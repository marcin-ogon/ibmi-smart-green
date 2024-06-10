**free
///
// Get current device state and color
//
// @param ostate Current state output variable.
// @param ocolor Current color output variable.
// 
// @author Marcin Ogoń
// @date 2024-05-23
///

ctl-opt dftactgrp(*no) main(main);

/define smart
/include 'qrpgleref/smart.rpgleinc'

dcl-proc main;
  dcl-pi *n;
    ostate like(StateNameTemplate);
    ocolor like(ColorNameTemplate);
  end-pi;

  dcl-ds smart_r qualified;
    state like(StateNameTemplate);
    color like(ColorNameTemplate);
  end-ds;

  exec sql select state, color into :smart_r from smartdev;
  if sqlcode = 0;
    ostate = smart_r.state;
    ocolor = smart_r.color;
  else;
    clear ostate;
    clear ocolor;
  endif;

  return;
end-proc;
