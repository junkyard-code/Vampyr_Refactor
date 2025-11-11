unit uAudioSDL;

{$mode objfpc}{$H+}

interface

uses
  SysUtils, Classes,
  sdl2; // make sure your compiler can find SDL2 Pascal bindings

type
  TSoundName = (
    snTitleSong,
    snRipSound,
    snReallyDead,
    snScary,
    snTwZone,
    snCongrats,
    snMagic,
    snMagic2,
    snMagic3,
    snCrunch,
    snScroll,
    snMiss,
    snPunch,
    snBattleCry,
    snBattleCry2,
    snSiren
  );

procedure SoundInit(const WAVFolder: string);   // call once at program start
procedure SoundShutdown;                        // call at program exit
procedure SetSoundEnabled(const AEnabled: Boolean);
function  GetSoundEnabled: Boolean;

procedure PlaySoundByName(Name: TSoundName);    // non-blocking
procedure StopAllSounds;                        // stops/clears queued audio

// Convenience wrappers matching your original procedure names
procedure PlayTitleSong;
procedure PlayRipSound;
procedure PlayReallyDeadSound;
procedure PlayScarySound;
procedure PlayTwZoneSound;
procedure PlayCongratsSound;
procedure PlayMagicSound;
procedure PlayMagicSound2;
procedure PlayMagicSound3;
procedure PlayCrunchSound;
procedure PlayScrollSound;
procedure PlayMissSound;
procedure PlayPunchSound;
procedure PlayBattleCrySound;
procedure PlayBattleCrySound2;
procedure PlaySirenSound;

implementation

type
  PSoundBuffer = ^TSoundBuffer;
  TSoundBuffer = record
    Buf: PUint8;       // pointer to converted audio data (device format)
    Len: UInt32;       // length in bytes
    OwnsMemory: Boolean; // whether we must FreeMem(Buf) on shutdown
    Loaded: Boolean;
  end;

var
  AudioDevice: Uint32 = 0;
  HaveSpec: TSDL_AudioSpec;
  SoundEnabled: Boolean = True;
  WAVDir: string = '';
  // simple map from enum ordinal to buffer
  SoundBuffers: array[TSoundName] of TSoundBuffer;

{--------------------------------------------------------------------
 Utility: filename mapping for each logical sound (WAV name)
 Keep names simple like 'TitleSong.wav', 'RipSound.wav', etc.
 You can change filenames or folder structure as you like.
--------------------------------------------------------------------}
function SoundFileNameFor(Name: TSoundName): string;
begin
  case Name of
    snTitleSong: Result := 'TitleSong.wav';
    snRipSound: Result := 'RipSound.wav';
    snReallyDead: Result := 'ReallyDeadSound.wav';
    snScary: Result := 'ScarySound.wav';
    snTwZone: Result := 'TwZoneSound.wav';
    snCongrats: Result := 'CongratsSound.wav';
    snMagic: Result := 'MagicSound.wav';
    snMagic2: Result := 'MagicSound2.wav';
    snMagic3: Result := 'MagicSound3.wav';
    snCrunch: Result := 'CrunchSound.wav';
    snScroll: Result := 'ScrollSound.wav';
    snMiss: Result := 'MissSound.wav';
    snPunch: Result := 'PunchSound.wav';
    snBattleCry: Result := 'BattleCrySound.wav';
    snBattleCry2: Result := 'BattleCrySound2.wav';
    snSiren: Result := 'SirenSound.wav';
  else
    Result := '';
  end;
end;

procedure FreeSoundBuffer(var SB: TSoundBuffer);
begin
  if SB.Loaded then
  begin
    if SB.OwnsMemory and Assigned(SB.Buf) then
      FreeMem(SB.Buf);
    SB.Buf := nil;
    SB.Len := 0;
    SB.Loaded := False;
    SB.OwnsMemory := False;
  end;
end;

{--------------------------------------------------------------------
 Load a WAV file and convert it to the device audio format once.
 Returns true on success, and stores converted data in SoundBuffers[idx].
--------------------------------------------------------------------}
function LoadAndConvertWAV(const FullPath: string; out SB: TSoundBuffer): Boolean;
var
  srcSpec: TSDL_AudioSpec;
  srcBuf: PUint8;
  srcLen: UInt32;
  needConvert: Boolean;
  cvt: TSDL_AudioCVT;
  converted: PUint8;
  convertedLen: Integer;
begin
  Result := False;
  SB.Loaded := False;
  SB.Buf := nil;
  SB.Len := 0;
  SB.OwnsMemory := False;

  if not FileExists(FullPath) then Exit;

  if SDL_LoadWAV(PAnsiChar(AnsiString(FullPath)), @srcSpec, @srcBuf, @srcLen) = nil then
    Exit;

  // if src spec matches device spec, we can use srcBuf directly by copying it
  needConvert := not ((srcSpec.format = HaveSpec.format) and
                      (srcSpec.channels = HaveSpec.channels) and
                      (srcSpec.freq = HaveSpec.freq));

  if not needConvert then
  begin
    // allocate buffer and copy
    GetMem(converted, srcLen);
    Move(srcBuf^, converted^, srcLen);
    convertedLen := srcLen;
    SB.Buf := converted;
    SB.Len := convertedLen;
    SB.OwnsMemory := True;
    SB.Loaded := True;
    // free original srcBuf provided by SDL_LoadWAV
    SDL_FreeWAV(srcBuf);
    Result := True;
    Exit;
  end;

  // build converter
  if SDL_BuildAudioCVT(@cvt, srcSpec.format, srcSpec.channels, srcSpec.freq,
                       HaveSpec.format, HaveSpec.channels, HaveSpec.freq) < 0 then
  begin
    SDL_FreeWAV(srcBuf);
    Exit;
  end;

  // allocate buffer for converted data (cvt.len_mult * srcLen + extra)
  cvt.len := srcLen;
  GetMem(cvt.buf, srcLen * cvt.len_mult + 32);
  Move(srcBuf^, cvt.buf^, srcLen);
  if SDL_ConvertAudio(@cvt) < 0 then
  begin
    FreeMem(cvt.buf);
    SDL_FreeWAV(srcBuf);
    Exit;
  end;

  convertedLen := cvt.len_cvt;
  // allocate exact buffer and copy converted bytes
  GetMem(converted, convertedLen);
  Move(cvt.buf^, converted^, convertedLen);

  // cleanup
  FreeMem(cvt.buf);
  SDL_FreeWAV(srcBuf);

  SB.Buf := converted;
  SB.Len := UInt32(convertedLen);
  SB.OwnsMemory := True;
  SB.Loaded := True;
  Result := True;
end;

{--------------------------------------------------------------------
 Initializes SDL audio and preloads all WAVs found in the WAV folder.
 WAVFolder: directory containing the WAV files (pass '' to use current dir).
 You may call this with relative or absolute path.
--------------------------------------------------------------------}
procedure SoundInit(const WAVFolder: string);
var
  i: TSoundName;
  wantSpec: TSDL_AudioSpec;
  fullpath: string;
  ok: Boolean;
begin
  if AudioDevice <> 0 then Exit; // already initialized

  WAVDir := WAVFolder;
  if (WAVDir = '') or (WAVDir = '.') then WAVDir := GetCurrentDir;
  if (WAVDir[length(WAVDir)] <> PathDelim) then WAVDir := WAVDir + PathDelim;

  if SDL_Init(SDL_INIT_AUDIO) < 0 then
    raise Exception.Create('SDL_Init(SDL_INIT_AUDIO) failed: ' + SDL_GetError);

  FillChar(wantSpec, SizeOf(wantSpec), 0);
  wantSpec.freq := 44100;
  wantSpec.format := AUDIO_S16SYS;
  wantSpec.channels := 1; // mono is fine for PC-speaker style; switch to 2 if you want stereo
  wantSpec.samples := 4096;

  AudioDevice := SDL_OpenAudioDevice(nil, 0, @wantSpec, @HaveSpec, 0);
  if AudioDevice = 0 then
  begin
    SDL_Quit;
    raise Exception.Create('SDL_OpenAudioDevice failed: ' + SDL_GetError);
  end;

  // start playback (unpaused)
  SDL_PauseAudioDevice(AudioDevice, 0);

  // preload each sound according to the mapping
  for i := Low(SoundBuffers) to High(SoundBuffers) do
  begin
    FreeSoundBuffer(SoundBuffers[i]);
    fullpath := WAVDir + SoundFileNameFor(i);
    ok := LoadAndConvertWAV(fullpath, SoundBuffers[i]);
    if not ok then
    begin
      // sound failed to load: keep Loaded = False; PlaySoundByName will no-op
      // optionally log to console
      Writeln(Format('Warning: sound file not loaded: %s', [fullpath]));
    end;
  end;
end;

procedure SoundShutdown;
var
  i: TSoundName;
begin
  if AudioDevice <> 0 then
  begin
    SDL_ClearQueuedAudio(AudioDevice);
    SDL_CloseAudioDevice(AudioDevice);
    AudioDevice := 0;
  end;

  // free buffers
  for i := Low(SoundBuffers) to High(SoundBuffers) do
    FreeSoundBuffer(SoundBuffers[i]);

  SDL_QuitSubSystem(SDL_INIT_AUDIO);
  SDL_Quit;
end;

procedure SetSoundEnabled(const AEnabled: Boolean);
begin
  SoundEnabled := AEnabled;
  if not SoundEnabled then
    StopAllSounds; // clear any queued audio immediately
end;

function GetSoundEnabled: Boolean;
begin
  Result := SoundEnabled;
end;

procedure StopAllSounds;
begin
  if (AudioDevice <> 0) then
    SDL_ClearQueuedAudio(AudioDevice);
end;

procedure PlaySoundByName(Name: TSoundName);
var
  SB: TSoundBuffer;
begin
  if not SoundEnabled then Exit;
  if AudioDevice = 0 then Exit; // audio not initialized
  SB := SoundBuffers[Name];
  if (not SB.Loaded) or (SB.Buf = nil) or (SB.Len = 0) then Exit;
  // queue audio (non-blocking)
  SDL_QueueAudio(AudioDevice, SB.Buf, SB.Len);
end;

{ Convenience wrappers that match the original names in your Music unit }
procedure PlayTitleSong;        begin PlaySoundByName(snTitleSong); end;
procedure PlayRipSound;         begin PlaySoundByName(snRipSound); end;
procedure PlayReallyDeadSound;  begin PlaySoundByName(snReallyDead); end;
procedure PlayScarySound;       begin PlaySoundByName(snScary); end;
procedure PlayTwZoneSound;      begin PlaySoundByName(snTwZone); end;
procedure PlayCongratsSound;    begin PlaySoundByName(snCongrats); end;
procedure PlayMagicSound;       begin PlaySoundByName(snMagic); end;
procedure PlayMagicSound2;      begin PlaySoundByName(snMagic2); end;
procedure PlayMagicSound3;      begin PlaySoundByName(snMagic3); end;
procedure PlayCrunchSound;      begin PlaySoundByName(snCrunch); end;
procedure PlayScrollSound;      begin PlaySoundByName(snScroll); end;
procedure PlayMissSound;        begin PlaySoundByName(snMiss); end;
procedure PlayPunchSound;       begin PlaySoundByName(snPunch); end;
procedure PlayBattleCrySound;   begin PlaySoundByName(snBattleCry); end;
procedure PlayBattleCrySound2;  begin PlaySoundByName(snBattleCry2); end;
procedure PlaySirenSound;       begin PlaySoundByName(snSiren); end;

end.
