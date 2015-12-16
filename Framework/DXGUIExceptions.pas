unit DXGUIExceptions;

interface

uses
  System.SysUtils;

type
  EDXGUIFrameworkException = class(Exception);
  EDXInvalidArgumentException = class(EDXGUIFrameworkException);

implementation

end.
