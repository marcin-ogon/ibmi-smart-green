**free
/// 
// Smart Device Control Program
// This program is designed to manage and control smart devices.
// It provides a subfile interface for users to interact with the devices.
// The subfile displays a list of devices, and users can select a device to control.
//
// The program provides the following functionalities:
// - LoadSubfile: This procedure loads the subfile with data from the SMARTDEV database.
// - HandleInputs: This procedure handles user inputs from the subfile.
// - ControlDevice: This procedure controls a device based on the user's input.
// - SwithState: This procedure switches the state of a device (ON/OFF).
// - ChangeColor: This procedure changes the color of a device.
//
// The program uses SQL to interact with the database.
// It uses cursor operations to fetch data from the database and to update the device state and color.
//
// @author Marcin Ogoń
// @date 2024-05-23
///

ctl-opt DFTACTGRP(*no);

dcl-c ENTER      X'F1';
dcl-c F03        X'33';

/define smart
/include 'qrpgleref/smart.rpgleinc'

dcl-f smartdf workstn sfile(SFLDTA:rrn) indds(fileind) infds(fileinfo);

dcl-ds fileind qualified;
  // Actions
  OnOff          ind  pos(7);
  ChangeColor    ind  pos(9);
  // Subfile
  SflDspCtl      ind  pos(85);
  SflDsp         ind  pos(95);
  // Colors Enabled
  ColorsEnabled  ind  pos(50);
  // Colors
  Red            ind  pos(51);
  Green          ind  pos(52);
  Blue           ind  pos(53);
  Colorinds      like(fileind.Red) dim(3) samepos(Red);
end-ds;

dcl-ds fileinfo;
  FUNKEY char(1) pos(369);
end-ds;

dcl-s exit ind inz(*off);
dcl-s rrn zoned(4:0) inz;

exit = *Off;
LoadSubfile();

dow (not exit);
  write HEAD;
  write FOOT;
  exfmt SFLCTL;

  select;
    when (Funkey = F03);
      exit = *On;
    when (Funkey = ENTER);
      HandleInputs();

  endsl;
enddo;

*inlr = *on;
return;

///
// Clear Subfile
// This procedure is responsible for clearing the subfile.
// It sets the subfile display control to off, clears the subfile, and sets the display control back on.
//
///
dcl-proc ClearSubfile;
  fileind.SflDspCtl = *Off;
  fileind.SflDsp = *Off;

  write SFLCTL;

  fileind.SflDspCtl = *On;

  rrn = 0;
end-proc;

///
// Load Subfile
// This procedure is responsible for loading data into the subfile.
// It fetches data from the database and populates the subfile with this data.
// Each row in the subfile corresponds to a record in the database.
//
///
dcl-proc LoadSubfile;
  dcl-ds device extname('SMARTDEV') qualified  end-ds;
  
  ClearSubfile();

  exec sql 
    declare devcursor cursor for
      select ID, DEVID, TYPE
      from SMARTDEV
      limit 9999;

  exec sql open devcursor;
  if (sqlstate = '00000');
    dou (sqlstate <> '00000');
      exec sql
        fetch next from devcursor
        into  :device.ID,
              :device.DEVID,
              :device.TYPE;

      if (sqlstate = '00000');
        XID   = device.ID;
        XDEVID= device.DEVID;
        XTYPE = device.TYPE;

        rrn += 1;
        write SFLDTA;
      endif;
    enddo;
  endif;

  exec sql close devcursor;

  if (rrn > 0);
    fileind.SflDsp = *On;
    SFLRRN = 1;
  endif;
end-proc;

///
// Handle Inputs
// This procedure is responsible for handling the inputs from the subfile.
// It reads the selected row from the subfile and performs the necessary actions based on the input.
// In this case, it controls the device based on the selected action.
//
///
dcl-proc HandleInputs;
  dcl-s selected Char(1);

  dou (%eof(smartdf));
    readc SFLDTA;
    if (%eof(smartdf));
      iter;
    endif;

    selected = %trim(xsel);

    select;
      when (selected = '2');
        dow (Funkey <> F03);
          ControlDevice(xid: xtype);
        enddo;
    endsl;

    if (XSEL <> *blank);
      XSEL = *blank;
      update SFLDTA;
      SFLRRN = rrn;
    endif;
  enddo;
end-proc;

///
// Control device
// This procedure is responsible for controlling the device.
//
// @param id: The device id.
// @param type: The device type.
///
dcl-proc ControlDevice;
  dcl-pi *n;
    id like(xid);
    type like(xtype);
  end-pi;
  // dcl-s color like(ColorNameTemplate);
  dcl-s index uns(3);

  exec sql 
    select 
      state, 
      color 
    into :xstate, :xcolor 
    from SMARTDEV 
    where id = :xid
    limit 1;

  if sqlcode <> 0;
    clear xstate;
    clear xcolor;
  endif;

  fileind.ColorsEnabled = %trim(type) = %trim(DeviceTypes.LIGHT);
  for index = 1 to DeviceColors.elems;
    fileind.Colorinds(index) = xcolor = DeviceColors.elem(index);
  endfor;

  write HEAD;
  exfmt CHANGE;

  select;
    when fileind.OnOff;
      xstate = SwithState(xid: xstate);

    when fileind.ChangeColor;
      xcolor = ChangeColor(xid: xcolor);

  endsl;
end-proc;

///
// Swith device state
// This procedure is responsible for handling the switch state.
// 
// @param id: The device id.
// @param switchState The current state of the swith. possible values are 'ON' or 'OFF'.
// @return New state
///
dcl-proc SwithState;
  dcl-pi *n like(xstate) ;
    id    like(xid);
    state like(xstate);
  end-pi;
  dcl-s tempState like(xstate);

  if state = DeviceStates.ON;
    tempState = DeviceStates.OFF;
  else;
    tempState = DeviceStates.ON;
  endif;

  exec sql 
    update smartdev 
      set 
        STATE = :tempState, 
        status='PROC', 
        last_change=current timestamp 
    where id = :id
    with nc;

  return tempState;  
end-proc;

///
// Change device color
// This procedure is responsible for changing the color.
// 
// @param id: The device id.
// @param color: The color to be changed to.
// @return New color
///
dcl-proc ChangeColor;
  dcl-pi *n like(xcolor);
    id    like(xid);
    color like(xcolor);
  end-pi;
  dcl-s tempColor like(xcolor);

  select;
    when color = DeviceColors.RED;
      tempColor = DeviceColors.GREEN;
    when color = DeviceColors.GREEN;
      tempColor = DeviceColors.BLUE;
    other;
      tempColor = DeviceColors.RED;
  endsl;

  exec sql  
    update smartdev 
      set STATE = 'ON', 
          COLOR = :tempColor, 
          status='PROC', 
          last_change=current timestamp 
    where id = :id
    with nc;

  return tempColor;  
end-proc;