| vim: ft=reva
|
| A little more complex test for the new GUI library and the GUI DB stuff...
|
| Author: Danny Reinhold / Reinhold Software Services
| Reva's license terms also apply to this file.

needs ui/gui
needs ui/gui-db
~ui-db
~iup
~ui

context: ~test-app
~test-app

value userForm

: my-db-form
  dbform: reva_user dup to userForm
    hboxs[
      | Empty label to create some space on the left side
      " " label[ " 10x10" size ]w spacer

      | Left column
      vbox[
        " Person" frame[
          " Mr/Mrs"     dbtext[  dbattr: mrOrMrs    ]dbt
          " First Name" dbtext[  dbattr: firstName  ]dbt
          " Last Name"  dbtext[  dbattr: lastName   ]dbt
        ]fr
        spacer
        " Address" frame[
          " Address"    dbtext[  dbattr: address    ]dbt
          " ZIP code"   dbtext[  dbattr: zipCode    ]dbt
          " City"       dbtext[  dbattr: city       ]dbt
          " County"     dbtext[  dbattr: county     ]dbt
          " Country"    dbtext[  dbattr: country    ]dbt
        ]fr
      ]w

      | Empty label to create some space
      spacer " " label[ " 10x10" size ]w spacer

      | Right column
      vbox[
        " Electronic Contact" frame[
          " Phone1"    dbtext[  dbattr: phone1      ]dbt
          " Phone2"    dbtext[  dbattr: phone2      ]dbt
          " Fax"       dbtext[  dbattr: fax         ]dbt
          " E-Mail"    dbtext[  dbattr: eMail       ]dbt
          " Website"   dbtext[  dbattr: website     ]dbt
        ]fr
        spacer
        " Remarks"     dbtext[  dbattr: remarks     ]dbt
      ]w

      | Empty label to create some space
      spacer " " label[ " 10x10" size ]w
    ]c
  ]w
;

:: userForm dump-db-form           gui-default ; 1024 cb: dumpButton
:: userForm dbinsert-stmt type cr  gui-default ; 1024 cb: insertButton
:: userForm dbupdate-stmt type cr  gui-default ; 1024 cb: updateButton
:: userForm dbselect-stmt type cr  gui-default ; 1024 cb: selectButton

: init-dlg
  dialog[
    my-db-form
    spacer
    hbox[
      " Dump"        button[  action: dumpDlg       ]w
      " Insert-STMT" button[  action: insertButton  ]w
      " Update-STMT" button[  action: updateButton  ]w
      " Select-STMT" button[  action: selectButton  ]w
      spacer
    ]w
    hboxs[  " Quit!" button[  action[  gui-close  ]a  ]w  ]c
  ]d  " Simple database dialog" title
;


: update-dlg
  userForm " 0815" dbid drop
;


: go  init-dlg  update-dlg show  gui-main-loop destroy  ;
to~ ~ go

exit~ | ~test-app
exit~ | ~ui
exit~ | ~ui-db

go bye
