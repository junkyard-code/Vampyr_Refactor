unit sdl2_dyn;

{$mode objfpc}{$H+}

interface

uses
  Windows, SysUtils;

// SDL2 version
const
  SDL_MAJOR_VERSION = 2;
  SDL_MINOR_VERSION = 30;
  SDL_PATCHLEVEL = 8;

type
  // Basic types
  PSDL_Window = Pointer;
  PSDL_Renderer = Pointer;
  PSDL_Texture = Pointer;
  PSDL_Surface = Pointer;

  // Rect structure
  PSDL_Rect = ^TSDL_Rect;
  TSDL_Rect = record
    x, y: Integer;
    w, h: Integer;
  end;

  // Event types
  TSDL_CommonEvent = record
    type_: UInt32;
    timestamp: UInt32;
  end;

  TSDL_WindowEvent = record
    type_: UInt32;
    timestamp: UInt32;
    windowID: UInt32;
    event: UInt8;
    padding1: UInt8;
    padding2: UInt8;
    padding3: UInt8;
    data1: Integer;
    data2: Integer;
  end;

  TSDL_Keysym = record
    scancode: Integer;
    sym: Integer;
    mod_: UInt16;
    unused: UInt32;
  end;

  TSDL_KeyboardEvent = record
    type_: UInt32;
    timestamp: UInt32;
    windowID: UInt32;
    state: UInt8;
    repeat_: UInt8;
    padding2: UInt8;
    padding3: UInt8;
    keysym: TSDL_Keysym;
  end;

  TSDL_TextEditingEvent = record
    type_: UInt32;
    timestamp: UInt32;
    windowID: UInt32;
    text: array[0..31] of AnsiChar;
    start: Integer;
    length: Integer;
  end;

  TSDL_TextInputEvent = record
    type_: UInt32;
    timestamp: UInt32;
    windowID: UInt32;
    text: array[0..31] of AnsiChar;
  end;

  TSDL_MouseMotionEvent = record
    type_: UInt32;
    timestamp: UInt32;
    windowID: UInt32;
    which: UInt32;
    state: UInt32;
    x: Integer;
    y: Integer;
    xrel: Integer;
    yrel: Integer;
  end;

  TSDL_MouseButtonEvent = record
    type_: UInt32;
    timestamp: UInt32;
    windowID: UInt32;
    which: UInt32;
    button: UInt8;
    state: UInt8;
    clicks: UInt8;
    padding1: UInt8;
    x: Integer;
    y: Integer;
  end;

  TSDL_MouseWheelEvent = record
    type_: UInt32;
    timestamp: UInt32;
    windowID: UInt32;
    which: UInt32;
    x: Integer;
    y: Integer;
    direction: UInt32;
  end;

  TSDL_JoyAxisEvent = record
    type_: UInt32;
    timestamp: UInt32;
    which: Integer;
    axis: UInt8;
    padding1: UInt8;
    padding2: UInt8;
    padding3: UInt8;
    value: Integer;
    padding4: UInt16;
  end;

  TSDL_JoyBallEvent = record
    type_: UInt32;
    timestamp: UInt32;
    which: Integer;
    ball: UInt8;
    padding1: UInt8;
    padding2: UInt8;
    padding3: UInt8;
    xrel: Integer;
    yrel: Integer;
  end;

  TSDL_JoyHatEvent = record
    type_: UInt32;
    timestamp: UInt32;
    which: Integer;
    hat: UInt8;
    value: UInt8;
    padding1: UInt8;
    padding2: UInt8;
  end;

  TSDL_JoyButtonEvent = record
    type_: UInt32;
    timestamp: UInt32;
    which: Integer;
    button: UInt8;
    state: UInt8;
    padding1: UInt8;
    padding2: UInt8;
  end;

  TSDL_JoyDeviceEvent = record
    type_: UInt32;
    timestamp: UInt32;
    which: Integer;
  end;

  TSDL_ControllerAxisEvent = record
    type_: UInt32;
    timestamp: UInt32;
    which: Integer;
    axis: UInt8;
    padding1: UInt8;
    padding2: UInt8;
    padding3: UInt8;
    value: Integer;
    padding4: UInt16;
  end;

  TSDL_ControllerButtonEvent = record
    type_: UInt32;
    timestamp: UInt32;
    which: Integer;
    button: UInt8;
    state: UInt8;
    padding1: UInt8;
    padding2: UInt8;
  end;

  TSDL_ControllerDeviceEvent = record
    type_: UInt32;
    timestamp: UInt32;
    which: Integer;
  end;

  TSDL_AudioDeviceEvent = record
    type_: UInt32;
    timestamp: UInt32;
    which: UInt32;
    iscapture: UInt8;
    padding1: UInt8;
    padding2: UInt8;
    padding3: UInt8;
  end;

  TSDL_TouchFingerEvent = record
    type_: UInt32;
    timestamp: UInt32;
    touchId: Int64;
    fingerId: Int64;
    x: Single;
    y: Single;
    dx: Single;
    dy: Single;
    pressure: Single;
  end;

  TSDL_MultiGestureEvent = record
    type_: UInt32;
    timestamp: UInt32;
    touchId: Int64;
    dTheta: Single;
    dDist: Single;
    x: Single;
    y: Single;
    numFingers: UInt16;
    padding: UInt16;
  end;

  TSDL_DollarGestureEvent = record
    type_: UInt32;
    timestamp: UInt32;
    touchId: Int64;
    gestureId: Int64;
    numFingers: UInt32;
    error: Single;
    x: Single;
    y: Single;
  end;

  TSDL_DropEvent = record
    type_: UInt32;
    timestamp: UInt32;
    file_: PAnsiChar;
    windowID: UInt32;
  end;

  TSDL_SensorEvent = record
    type_: UInt32;
    timestamp: UInt32;
    which: Integer;
    data: array[0..5] of Single;
  end;

  TSDL_QuitEvent = record
    type_: UInt32;
    timestamp: UInt32;
  end;

  TSDL_OSEvent = record
    type_: UInt32;
    timestamp: UInt32;
  end;

  TSDL_UserEvent = record
    type_: UInt32;
    timestamp: UInt32;
    windowID: UInt32;
    code: Integer;
    data1: Pointer;
    data2: Pointer;
  end;

  TSDL_SysWMmsg = record
    // Platform specific structure
  end;

  PSDL_SysWMmsg = ^TSDL_SysWMmsg;

  TSDL_SysWMEvent = record
    type_: UInt32;
    timestamp: UInt32;
    msg: PSDL_SysWMmsg;
  end;

  TSDL_Event = record
    case Integer of
      0: (type_: UInt32);
      1: (common: TSDL_CommonEvent);
      2: (window: TSDL_WindowEvent);
      3: (key: TSDL_KeyboardEvent);
      4: (edit: TSDL_TextEditingEvent);
      5: (text: TSDL_TextInputEvent);
      6: (motion: TSDL_MouseMotionEvent);
      7: (button: TSDL_MouseButtonEvent);
      8: (wheel: TSDL_MouseWheelEvent);
      9: (jaxis: TSDL_JoyAxisEvent);
      10: (jball: TSDL_JoyBallEvent);
      11: (jhat: TSDL_JoyHatEvent);
      12: (jbutton: TSDL_JoyButtonEvent);
      13: (jdevice: TSDL_JoyDeviceEvent);
      14: (caxis: TSDL_ControllerAxisEvent);
      15: (cbutton: TSDL_ControllerButtonEvent);
      16: (cdevice: TSDL_ControllerDeviceEvent);
      17: (adevice: TSDL_AudioDeviceEvent);
      18: (quit: TSDL_QuitEvent);
      19: (user: TSDL_UserEvent);
      20: (syswm: TSDL_SysWMEvent);
      21: (tfinger: TSDL_TouchFingerEvent);
      22: (mgesture: TSDL_MultiGestureEvent);
      23: (dgesture: TSDL_DollarGestureEvent);
      24: (drop: TSDL_DropEvent);
      25: (sensor: TSDL_SensorEvent);
      26: (padding: array[0..55] of UInt8);
  end;
  
  PSDL_Event = ^TSDL_Event;

  // Key codes
const
  SDLK_UNKNOWN = 0;
  SDLK_RETURN = 13;
  SDLK_ESCAPE = 27;
  SDLK_BACKSPACE = 8;
  SDLK_TAB = 9;
  SDLK_SPACE = 32;
  SDLK_EXCLAIM = 33;
  SDLK_QUOTEDBL = 34;
  SDLK_HASH = 35;
  SDLK_DOLLAR = 36;
  SDLK_PERCENT = 37;
  SDLK_AMPERSAND = 38;
  SDLK_QUOTE = 39;
  SDLK_LEFTPAREN = 40;
  SDLK_RIGHTPAREN = 41;
  SDLK_ASTERISK = 42;
  SDLK_PLUS = 43;
  SDLK_COMMA = 44;
  SDLK_MINUS = 45;
  SDLK_PERIOD = 46;
  SDLK_SLASH = 47;
  SDLK_0 = 48;
  SDLK_1 = 49;
  SDLK_2 = 50;
  SDLK_3 = 51;
  SDLK_4 = 52;
  SDLK_5 = 53;
  SDLK_6 = 54;
  SDLK_7 = 55;
  SDLK_8 = 56;
  SDLK_9 = 57;
  SDLK_COLON = 58;
  SDLK_SEMICOLON = 59;
  SDLK_LESS = 60;
  SDLK_EQUALS = 61;
  SDLK_GREATER = 62;
  SDLK_QUESTION = 63;
  SDLK_AT = 64;
  SDLK_LEFTBRACKET = 91;
  SDLK_BACKSLASH = 92;
  SDLK_RIGHTBRACKET = 93;
  SDLK_CARET = 94;
  SDLK_UNDERSCORE = 95;
  SDLK_BACKQUOTE = 96;
  SDLK_a = 97;
  SDLK_b = 98;
  SDLK_c = 99;
  SDLK_d = 100;
  SDLK_e = 101;
  SDLK_f = 102;
  SDLK_g = 103;
  SDLK_h = 104;
  SDLK_i = 105;
  SDLK_j = 106;
  SDLK_k = 107;
  SDLK_l = 108;
  SDLK_m = 109;
  SDLK_n = 110;
  SDLK_o = 111;
  SDLK_p = 112;
  SDLK_q = 113;
  SDLK_r = 114;
  SDLK_s = 115;
  SDLK_t = 116;
  SDLK_u = 117;
  SDLK_v = 118;
  SDLK_w = 119;
  SDLK_x = 120;
  SDLK_y = 121;
  SDLK_z = 122;
  SDLK_CAPSLOCK = 1073741881;
  SDLK_F1 = 1073741882;
  SDLK_F2 = 1073741883;
  SDLK_F3 = 1073741884;
  SDLK_F4 = 1073741885;
  SDLK_F5 = 1073741886;
  SDLK_F6 = 1073741887;
  SDLK_F7 = 1073741888;
  SDLK_F8 = 1073741889;
  SDLK_F9 = 1073741890;
  SDLK_F10 = 1073741891;
  SDLK_F11 = 1073741892;
  SDLK_F12 = 1073741893;
  SDLK_PRINTSCREEN = 1073741894;
  SDLK_SCROLLLOCK = 1073741895;
  SDLK_PAUSE = 1073741896;
  SDLK_INSERT = 1073741897;
  SDLK_HOME = 1073741898;
  SDLK_PAGEUP = 1073741899;
  SDLK_DELETE = 127;
  SDLK_END = 1073741901;
  SDLK_PAGEDOWN = 1073741902;
  SDLK_RIGHT = 1073741903;
  SDLK_LEFT = 1073741904;
  SDLK_DOWN = 1073741905;
  SDLK_UP = 1073741906;
  SDLK_NUMLOCKCLEAR = 1073741907;
  SDLK_KP_DIVIDE = 1073741908;
  SDLK_KP_MULTIPLY = 1073741909;
  SDLK_KP_MINUS = 1073741910;
  SDLK_KP_PLUS = 1073741911;
  SDLK_KP_ENTER = 1073741912;
  SDLK_KP_1 = 1073741913;
  SDLK_KP_2 = 1073741914;
  SDLK_KP_3 = 1073741915;
  SDLK_KP_4 = 1073741916;
  SDLK_KP_5 = 1073741917;
  SDLK_KP_6 = 1073741918;
  SDLK_KP_7 = 1073741919;
  SDLK_KP_8 = 1073741920;
  SDLK_KP_9 = 1073741921;
  SDLK_KP_0 = 1073741922;
  SDLK_KP_PERIOD = 1073741923;
  SDLK_APPLICATION = 1073741925;
  SDLK_POWER = 1073741926;
  SDLK_KP_EQUALS = 1073741927;
  SDLK_F13 = 1073741928;
  SDLK_F14 = 1073741929;
  SDLK_F15 = 1073741930;
  SDLK_F16 = 1073741931;
  SDLK_F17 = 1073741932;
  SDLK_F18 = 1073741933;
  SDLK_F19 = 1073741934;
  SDLK_F20 = 1073741935;
  SDLK_F21 = 1073741936;
  SDLK_F22 = 1073741937;
  SDLK_F23 = 1073741938;
  SDLK_F24 = 1073741939;
  SDLK_EXECUTE = 1073741940;
  SDLK_HELP = 1073741941;
  SDLK_MENU = 1073741942;
  SDLK_SELECT = 1073741943;
  SDLK_STOP = 1073741944;
  SDLK_AGAIN = 1073741945;
  SDLK_UNDO = 1073741946;
  SDLK_CUT = 1073741947;
  SDLK_COPY = 1073741948;
  SDLK_PASTE = 1073741949;
  SDLK_FIND = 1073741950;
  SDLK_MUTE = 1073741951;
  SDLK_VOLUMEUP = 1073741952;
  SDLK_VOLUMEDOWN = 1073741953;
  SDLK_KP_COMMA = 1073741957;
  SDLK_KP_EQUALSAS400 = 1073741958;
  SDLK_ALTERASE = 1073741977;
  SDLK_SYSREQ = 1073741978;
  SDLK_CANCEL = 1073741979;
  SDLK_CLEAR = 1073741980;
  SDLK_PRIOR = 1073741981;
  SDLK_RETURN2 = 1073741982;
  SDLK_SEPARATOR = 1073741983;
  SDLK_OUT = 1073741984;
  SDLK_OPER = 1073741985;
  SDLK_CLEARAGAIN = 1073741986;
  SDLK_CRSEL = 1073741987;
  SDLK_EXSEL = 1073741988;
  SDLK_KP_00 = 1073742000;
  SDLK_KP_000 = 1073742001;
  SDLK_THOUSANDSSEPARATOR = 1073742002;
  SDLK_DECIMALSEPARATOR = 1073742003;
  SDLK_CURRENCYUNIT = 1073742004;
  SDLK_CURRENCYSUBUNIT = 1073742005;
  SDLK_KP_LEFTPAREN = 1073742006;
  SDLK_KP_RIGHTPAREN = 1073742007;
  SDLK_KP_LEFTBRACE = 1073742008;
  SDLK_KP_RIGHTBRACE = 1073742009;
  SDLK_KP_TAB = 1073742010;
  SDLK_KP_BACKSPACE = 1073742011;
  SDLK_KP_A = 1073742012;
  SDLK_KP_B = 1073742013;
  SDLK_KP_C = 1073742014;
  SDLK_KP_D = 1073742015;
  SDLK_KP_E = 1073742016;
  SDLK_KP_F = 1073742017;
  SDLK_KP_XOR = 1073742018;
  SDLK_KP_POWER = 1073742019;
  SDLK_KP_PERCENT = 1073742020;
  SDLK_KP_LESS = 1073742021;
  SDLK_KP_GREATER = 1073742022;
  SDLK_KP_AMPERSAND = 1073742023;
  SDLK_KP_DBLAMPERSAND = 1073742024;
  SDLK_KP_VERTICALBAR = 1073742025;
  SDLK_KP_DBLVERTICALBAR = 1073742026;
  SDLK_KP_COLON = 1073742027;
  SDLK_KP_HASH = 1073742028;
  SDLK_KP_SPACE = 1073742029;
  SDLK_KP_AT = 1073742030;
  SDLK_KP_EXCLAM = 1073742031;
  SDLK_KP_MEMSTORE = 1073742032;
  SDLK_KP_MEMRECALL = 1073742033;
  SDLK_KP_MEMCLEAR = 1073742034;
  SDLK_KP_MEMADD = 1073742035;
  SDLK_KP_MEMSUBTRACT = 1073742036;
  SDLK_KP_MEMMULTIPLY = 1073742037;
  SDLK_KP_MEMDIVIDE = 1073742038;
  SDLK_KP_PLUSMINUS = 1073742039;
  SDLK_KP_CLEAR = 1073742040;
  SDLK_KP_CLEARENTRY = 1073742041;
  SDLK_KP_BINARY = 1073742042;
  SDLK_KP_OCTAL = 1073742043;
  SDLK_KP_DECIMAL = 1073742044;
  SDLK_KP_HEXADECIMAL = 1073742045;
  SDLK_LCTRL = 1073742048;
  SDLK_LSHIFT = 1073742049;
  SDLK_LALT = 1073742050;
  SDLK_LGUI = 1073742051;
  SDLK_RCTRL = 1073742052;
  SDLK_RSHIFT = 1073742053;
  SDLK_RALT = 1073742054;
  SDLK_RGUI = 1073742055;
  SDLK_MODE = 1073742081;
  SDLK_AUDIONEXT = 1073742082;
  SDLK_AUDIOPREV = 1073742083;
  SDLK_AUDIOSTOP = 1073742084;
  SDLK_AUDIOPLAY = 1073742085;
  SDLK_AUDIOMUTE = 1073742086;
  SDLK_MEDIASELECT = 1073742087;
  SDLK_WWW = 1073742088;
  SDLK_MAIL = 1073742089;
  SDLK_CALCULATOR = 1073742090;
  SDLK_COMPUTER = 1073742091;
  SDLK_AC_SEARCH = 1073742092;
  SDLK_AC_HOME = 1073742093;
  SDLK_AC_BACK = 1073742094;
  SDLK_AC_FORWARD = 1073742095;
  SDLK_AC_STOP = 1073742096;
  SDLK_AC_REFRESH = 1073742097;
  SDLK_AC_BOOKMARKS = 1073742098;
  SDLK_BRIGHTNESSDOWN = 1073742099;
  SDLK_BRIGHTNESSUP = 1073742100;
  SDLK_DISPLAYSWITCH = 1073742101;
  SDLK_KBDILLUMTOGGLE = 1073742102;
  SDLK_KBDILLUMDOWN = 1073742103;
  SDLK_KBDILLUMUP = 1073742104;
  SDLK_EJECT = 1073742105;
  SDLK_SLEEP = 1073742106;
  SDLK_APP1 = 1073742107;
  SDLK_APP2 = 1073742108;
  SDLK_AUDIOREWIND = 1073742109;
  SDLK_AUDIOFASTFORWARD = 1073742110;

const
  // SDL_Init flags
  SDL_INIT_TIMER          = $00000001;
  SDL_INIT_AUDIO          = $00000010;
  SDL_INIT_VIDEO          = $00000020;
  SDL_INIT_JOYSTICK       = $00000200;
  SDL_INIT_HAPTIC         = $00001000;
  SDL_INIT_GAMECONTROLLER = $00002000;
  SDL_INIT_EVENTS         = $00004000;
  SDL_INIT_NOPARACHUTE    = $00100000;
  SDL_INIT_EVERYTHING     = SDL_INIT_TIMER or SDL_INIT_AUDIO or SDL_INIT_VIDEO or 
                           SDL_INIT_JOYSTICK or SDL_INIT_HAPTIC or 
                           SDL_INIT_GAMECONTROLLER or SDL_INIT_EVENTS;

  // Window flags
  SDL_WINDOW_FULLSCREEN = $00000001;
  SDL_WINDOW_OPENGL = $00000002;
  SDL_WINDOW_SHOWN = $00000004;
  SDL_WINDOW_HIDDEN = $00000008;
  SDL_WINDOW_BORDERLESS = $00000010;
  SDL_WINDOW_RESIZABLE = $00000020;
  SDL_WINDOW_MINIMIZED = $00000040;
  SDL_WINDOW_MAXIMIZED = $00000080;
  SDL_WINDOW_INPUT_GRABBED = $00000100;
  SDL_WINDOW_INPUT_FOCUS = $00000200;
  SDL_WINDOW_MOUSE_FOCUS = $00000400;
  SDL_WINDOW_FOREIGN = $00000800;
  SDL_WINDOW_FULLSCREEN_DESKTOP = SDL_WINDOW_FULLSCREEN or $00001000;
  SDL_WINDOW_ALLOW_HIGHDPI = $00002000;
  SDL_WINDOW_MOUSE_CAPTURE = $00004000;
  SDL_WINDOW_ALWAYS_ON_TOP = $00008000;
  SDL_WINDOW_SKIP_TASKBAR = $00010000;
  SDL_WINDOW_UTILITY = $00020000;
  SDL_WINDOW_TOOLTIP = $00040000;
  SDL_WINDOW_POPUP_MENU = $00080000;
  SDL_WINDOW_VULKAN = $10000000;

  // Window position
  SDL_WINDOWPOS_UNDEFINED = $1FFF0000;
  SDL_WINDOWPOS_CENTERED = $2FFF0000;

  // Renderer flags
  SDL_RENDERER_SOFTWARE = $00000001;
  SDL_RENDERER_ACCELERATED = $00000002;
  SDL_RENDERER_PRESENTVSYNC = $00000004;
  SDL_RENDERER_TARGETTEXTURE = $00000008;

  // Pixel formats
  SDL_PIXELFORMAT_UNKNOWN = 0;
  SDL_PIXELFORMAT_INDEX1LSB = 286261504;
  SDL_PIXELFORMAT_INDEX1MSB = 287310080;
  SDL_PIXELFORMAT_INDEX4LSB = 303039488;
  SDL_PIXELFORMAT_INDEX4MSB = 304088064;
  SDL_PIXELFORMAT_INDEX8 = 318769153;
  SDL_PIXELFORMAT_RGB332 = 336660481;
  SDL_PIXELFORMAT_RGB444 = 353504258;
  SDL_PIXELFORMAT_RGB555 = 353570562;
  SDL_PIXELFORMAT_BGR555 = 357764866;
  SDL_PIXELFORMAT_ARGB4444 = 355602946;
  SDL_PIXELFORMAT_RGBA4444 = 356651010;
  SDL_PIXELFORMAT_ABGR4444 = 359400194;
  SDL_PIXELFORMAT_BGRA4444 = 360448258;
  SDL_PIXELFORMAT_ARGB1555 = 355467523;
  SDL_PIXELFORMAT_RGBA5551 = 356651779;
  SDL_PIXELFORMAT_ABGR1555 = 358612483;
  SDL_PIXELFORMAT_BGRA5551 = 357796867;
  SDL_PIXELFORMAT_RGB565 = 353701890;
  SDL_PIXELFORMAT_BGR565 = 357896194;
  SDL_PIXELFORMAT_RGB24 = 386930691;
  SDL_PIXELFORMAT_BGR24 = 390076419;
  SDL_PIXELFORMAT_RGB888 = 370546692;
  SDL_PIXELFORMAT_RGBX8888 = 371595268;
  SDL_PIXELFORMAT_BGR888 = 369098756;
  SDL_PIXELFORMAT_BGRX8888 = 370147332;
  SDL_PIXELFORMAT_ARGB8888 = 372645892;
  SDL_PIXELFORMAT_RGBA8888 = 373694468;
  SDL_PIXELFORMAT_ABGR8888 = 376443652;
  SDL_PIXELFORMAT_BGRA8888 = 377492228;
  SDL_PIXELFORMAT_ARGB2101010 = 372711428;
  SDL_PIXELFORMAT_YV12 = 842094169;
  SDL_PIXELFORMAT_IYUV = 1448433993;
  SDL_PIXELFORMAT_YUY2 = 844715353;
  SDL_PIXELFORMAT_UYVY = 1498831189;
  SDL_PIXELFORMAT_YVYU = 1431918169;
  SDL_PIXELFORMAT_NV12 = 842094158;
  SDL_PIXELFORMAT_NV21 = 825382478;

  // Texture access
  SDL_TEXTUREACCESS_STATIC = 0;
  SDL_TEXTUREACCESS_STREAMING = 1;
  SDL_TEXTUREACCESS_TARGET = 2;

  // Event types
  SDL_QUITEV = $100;
  SDL_APP_TERMINATING = $100;
  SDL_APP_LOWMEMORY = $101;
  SDL_APP_WILLENTERBACKGROUND = $102;
  SDL_APP_DIDENTERBACKGROUND = $103;
  SDL_APP_WILLENTERFOREGROUND = $104;
  SDL_APP_DIDENTERFOREGROUND = $105;
  SDL_DISPLAYEVENT = $150;
  SDL_WINDOWEVENT = $200;
  SDL_SYSWMEVENT = $201;
  SDL_KEYDOWN = $300;
  SDL_KEYUP = $301;
  SDL_TEXTEDITING = $302;
  SDL_TEXTINPUT = $303;
  SDL_KEYMAPCHANGED = $304;
  SDL_MOUSEMOTION = $400;
  SDL_MOUSEBUTTONDOWN = $401;
  SDL_MOUSEBUTTONUP = $402;
  SDL_MOUSEWHEEL = $403;
  SDL_JOYAXISMOTION = $600;
  SDL_JOYBALLMOTION = $601;
  SDL_JOYHATMOTION = $602;
  SDL_JOYBUTTONDOWN = $603;
  SDL_JOYBUTTONUP = $604;
  SDL_JOYDEVICEADDED = $605;
  SDL_JOYDEVICEREMOVED = $606;
  SDL_CONTROLLERAXISMOTION = $650;
  SDL_CONTROLLERBUTTONDOWN = $651;
  SDL_CONTROLLERBUTTONUP = $652;
  SDL_CONTROLLERDEVICEADDED = $653;
  SDL_CONTROLLERDEVICEREMOVED = $654;
  SDL_CONTROLLERDEVICEREMAPPED = $655;
  SDL_FINGERDOWN = $700;
  SDL_FINGERUP = $701;
  SDL_FINGERMOTION = $702;
  SDL_DOLLARGESTURE = $800;
  SDL_DOLLARRECORD = $801;
  SDL_MULTIGESTURE = $802;
  SDL_CLIPBOARDUPDATE = $900;
  SDL_DROPFILE = $1000;
  SDL_DROPTEXT = $1001;
  SDL_DROPBEGIN = $1002;
  SDL_DROPCOMPLETE = $1003;
  SDL_AUDIODEVICEADDED = $1100;
  SDL_AUDIODEVICEREMOVED = $1101;
  SDL_SENSORUPDATE = $1200;
  SDL_RENDER_TARGETS_RESET = $2000;
  SDL_RENDER_DEVICE_RESET = $2001;
  SDL_USEREVENT = $8000;
  SDL_LASTEVENT = $FFFF;

var
  // Core SDL functions
  SDL_Init: function(flags: UInt32): Integer; cdecl;
  SDL_InitSubSystem: function(flags: UInt32): Integer; cdecl;
  SDL_QuitSubSystem: procedure(flags: UInt32); cdecl;
  SDL_WasInit: function(flags: UInt32): UInt32; cdecl;
  SDL_Quit: procedure; cdecl;
  
  // Window management
  SDL_CreateWindow: function(const title: PAnsiChar; x, y, w, h: Integer; flags: UInt32): PSDL_Window; cdecl;
  SDL_DestroyWindow: procedure(window: PSDL_Window); cdecl;
  SDL_GetWindowSize: procedure(window: PSDL_Window; w, h: PInteger); cdecl;
  SDL_SetWindowTitle: procedure(window: PSDL_Window; const title: PAnsiChar); cdecl;
  
  // Renderer
  SDL_CreateRenderer: function(window: PSDL_Window; index: Integer; flags: UInt32): PSDL_Renderer; cdecl;
  SDL_DestroyRenderer: procedure(renderer: PSDL_Renderer); cdecl;
  SDL_SetRenderDrawColor: function(renderer: PSDL_Renderer; r, g, b, a: UInt8): Integer; cdecl;
  SDL_RenderClear: function(renderer: PSDL_Renderer): Integer; cdecl;
  SDL_RenderPresent: procedure(renderer: PSDL_Renderer); cdecl;
  SDL_RenderCopy: function(renderer: PSDL_Renderer; texture: PSDL_Texture; const srcrect, dstrect: PSDL_Rect): Integer; cdecl;
  
  // Texture
  SDL_CreateTexture: function(renderer: PSDL_Renderer; format: UInt32; access, w, h: Integer): PSDL_Texture; cdecl;
  SDL_DestroyTexture: procedure(texture: PSDL_Texture); cdecl;
  SDL_UpdateTexture: function(texture: PSDL_Texture; const rect: PSDL_Rect; const pixels: Pointer; pitch: Integer): Integer; cdecl;
  
  // Surface
  SDL_CreateRGBSurface: function(flags: UInt32; width, height, depth: Integer; 
    Rmask, Gmask, Bmask, Amask: UInt32): PSDL_Surface; cdecl;
  SDL_FreeSurface: procedure(surface: PSDL_Surface); cdecl;
  
  // Event handling
  SDL_PollEvent: function(event: PSDL_Event): Integer; cdecl;
  SDL_WaitEvent: function(event: PSDL_Event): Integer; cdecl;
  SDL_PumpEvents: procedure; cdecl;
  
  // Timer
  SDL_GetTicks: function: UInt32; cdecl;
  SDL_Delay: procedure(ms: UInt32); cdecl;
  
  // Error handling
  SDL_GetError: function: PAnsiChar; cdecl;
  SDL_ClearError: procedure; cdecl;

implementation

var
  SDLHandle: THandle = 0;
  SDLLoaded: Boolean = False;

function SDL_LoadLibrary: Boolean;
var
  DllPath: string;
  
  function GetFunction(const Name: string): Pointer;
  begin
    Result := GetProcAddress(SDLHandle, PChar(Name));
    if Result = nil then
      WriteLn('Failed to load function: ', Name, ' (Error: ', GetLastError, ')');
  end;
  
  function GetProc(const Name: string; var FuncPtr): Boolean;
  begin
    Pointer(FuncPtr) := GetProcAddress(SDLHandle, PChar(Name));
    Result := Assigned(Pointer(FuncPtr));
    if not Result then
      WriteLn('Failed to load function: ', Name, ' (Error: ', GetLastError, ')');
  end;
  
begin
  if SDLLoaded then
    Exit(True);
    
  // Try to load the library from the application directory first
  DllPath := ExtractFilePath(ParamStr(0)) + 'SDL2.dll';
  WriteLn('Trying to load: ', DllPath);
  SDLHandle := LoadLibrary(PChar(DllPath));
  
  // If not found in the app directory, try system paths
  if SDLHandle = 0 then
  begin
    WriteLn('Trying to load from system paths...');
    SDLHandle := LoadLibrary('SDL2.dll');
  end;
    
  if SDLHandle = 0 then
  begin
    WriteLn('Failed to load SDL2.dll. Error: ', GetLastError);
    Exit(False);
  end;
  
  WriteLn('Successfully loaded SDL2.dll');
    
  // Load all the functions
  // Core functions
  GetProc('SDL_Init', SDL_Init);
  GetProc('SDL_InitSubSystem', SDL_InitSubSystem);
  GetProc('SDL_QuitSubSystem', SDL_QuitSubSystem);
  GetProc('SDL_WasInit', SDL_WasInit);
  GetProc('SDL_Quit', SDL_Quit);
  
  // Window functions
  GetProc('SDL_CreateWindow', SDL_CreateWindow);
  GetProc('SDL_DestroyWindow', SDL_DestroyWindow);
  GetProc('SDL_GetWindowSize', SDL_GetWindowSize);
  GetProc('SDL_SetWindowTitle', SDL_SetWindowTitle);
  
  // Renderer functions
  GetProc('SDL_CreateRenderer', SDL_CreateRenderer);
  GetProc('SDL_DestroyRenderer', SDL_DestroyRenderer);
  GetProc('SDL_SetRenderDrawColor', SDL_SetRenderDrawColor);
  GetProc('SDL_RenderClear', SDL_RenderClear);
  GetProc('SDL_RenderPresent', SDL_RenderPresent);
  GetProc('SDL_RenderCopy', SDL_RenderCopy);
  
  // Texture functions
  GetProc('SDL_CreateTexture', SDL_CreateTexture);
  GetProc('SDL_DestroyTexture', SDL_DestroyTexture);
  GetProc('SDL_UpdateTexture', SDL_UpdateTexture);
  
  // Surface functions
  GetProc('SDL_CreateRGBSurface', SDL_CreateRGBSurface);
  GetProc('SDL_FreeSurface', SDL_FreeSurface);
  
  // Event functions
  GetProc('SDL_PollEvent', SDL_PollEvent);
  GetProc('SDL_WaitEvent', SDL_WaitEvent);
  GetProc('SDL_PumpEvents', SDL_PumpEvents);
  
  // Timer functions
  GetProc('SDL_GetTicks', SDL_GetTicks);
  GetProc('SDL_Delay', SDL_Delay);
  
  // Error handling
  GetProc('SDL_GetError', SDL_GetError);
  GetProc('SDL_ClearError', SDL_ClearError);
  
  // Verify all required functions were loaded
  SDLLoaded := Assigned(SDL_Init) and Assigned(SDL_CreateWindow) and 
               Assigned(SDL_CreateRenderer) and Assigned(SDL_PollEvent) and
               Assigned(SDL_Quit) and Assigned(SDL_GetTicks) and
               Assigned(SDL_GetError);
  
  WriteLn('Checking required SDL2 functions:');
  WriteLn('  SDL_Init: ', Integer(Assigned(SDL_Init)));
  WriteLn('  SDL_CreateWindow: ', Integer(Assigned(SDL_CreateWindow)));
  WriteLn('  SDL_CreateRenderer: ', Integer(Assigned(SDL_CreateRenderer)));
  WriteLn('  SDL_PollEvent: ', Integer(Assigned(SDL_PollEvent)));
  WriteLn('  SDL_Quit: ', Integer(Assigned(SDL_Quit)));
  WriteLn('  SDL_GetTicks: ', Integer(Assigned(SDL_GetTicks)));
  WriteLn('  SDL_GetError: ', Integer(Assigned(SDL_GetError)));
  
  if not SDLLoaded then
  begin
    WriteLn('Failed to load required SDL2 functions');
    FreeLibrary(SDLHandle);
    SDLHandle := 0;
    Exit(False);
  end;
  
  WriteLn('Successfully loaded all required SDL2 functions');
  // Additional functions
  GetProc('SDL_UpdateTexture', SDL_UpdateTexture);
  
  Result := True;
end;

procedure SDL_UnloadLibrary;
begin
  if SDLHandle <> 0 then
  begin
    FreeLibrary(SDLHandle);
    SDLHandle := 0;
  end;
end;

initialization
  // Nothing to do here

finalization
  // Make sure to unload the library when the program ends
  SDL_UnloadLibrary;

end.
