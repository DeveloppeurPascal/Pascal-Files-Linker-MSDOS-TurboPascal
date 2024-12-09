Program Lk_Pascal;           { mise … jour le 27 - 01 - 1991 }

{
Ce programme permet de linker les fichiers sources au format de Turbo Pascal.
La directive de linkage etant $I (pour Include), ce programme la recherche, et
remplace la ligne la contenant par le fichier de nom sp‚cifi‚.


Auteur: Pr‚martin Patrick.
Date de la version 1.0 : 27 Janvier 1991.
}

Uses olf_software,
     u_Fenetre,
     u_Sgf,
     u_ger_Chaine,
     u_aff_Chaine,
     Crt;

Const
     Ver_Num : String [3]  = '1.0';
      Ver_Dat : String [10] = '27-01-1991';
      Param   : Boolean     = False;

Var   Nom_Fich_Orig,           { Nom du fichier de d‚part                   }
      Nom_Fich_Dest : String;  { Nom du fichier d'arriv‚e                   }
      Fichier1      : Text;    { Nom interne du fichier d'arriv‚e           }
      Num_Ligne,               { Num‚ro de la ligne courante dans Fichier1  }
      Nb_Niveau     : Integer; { Nombre de niveaux de fichiers ouverts      }

Procedure Attente_Appuit_Touche;
Var Carac        : Char;
    Old_Textattr : Integer;
Begin { attente_appuit_touche }
  While (Keypressed) Do
    Carac := Readkey
  {endwhile};
  Old_Textattr := Textattr;
  Textcolor (White);
  Textbackground (Black);
  Affic_Center_Ln ('Appuyez sur une touche.');
  Textattr := Old_Textattr;
  Carac := Readkey;
  While (Keypressed) Do
    Carac := Readkey
  {endwhile};
  Gotoxy (1, Wherey);
  Clreol
End; { attente_appuit_touche }

Procedure Informations;
Begin { informations }
  Type_Cadre := 5;
  Window_Fond_Cadre_Bis (2, 2, 79, 23, Lightgray, Black, Blue);
  Window_Titre ('Linkeur de fichiers Turbo Pascal.', Red, Green);
  Textcolor (Brown);
  Textbackground (Lightgray);
  Affic_Center_Ln ('Auteur: Pr‚martin Patrick.');
  Affic_Center_Ln (Concat ('Version: ', Ver_Num, ' dat‚e du ', Ver_Dat, '.'));
  Writeln;
  Writeln ('   Ce programme prend un fichier en Turbo Pascal, et y rajoute tous les');
  Writeln ('fichiers dont il est question derriŠre les directives $I (bien sur, ce');
  Writeln ('travail se fait … l''endroit mˆme des directives de compilation).');
  Writeln;
  Writeln ('   Vous pouvez lancer ce programme comme suit:');
  Writeln ('      LK_PASCA NOM_FICHIER_A_LIRE NOM_FICHIER_FINAL');
  Writeln ('si vous ne mettez que le premier fichier, le second prendra le mˆme nom');
  Writeln ('et l''inclusion se fera dans le fichier de d‚part.');
  Writeln;
  Writeln ('   Attention: il ‚xiste un risque … utiliser cette m‚thode si le programme');
  Writeln ('que vous complŠterez avec les $I n''est pas parfaitement au point, en');
  Writeln ('effet, vous serez oblig‚ d''y rechercher les modifications … faire, et vous');
  Writeln ('n''aurez plus la possibilit‚ d''utiliser … nouveau les fichiers inclus...');
  Writeln;
  Attente_Appuit_Touche;
  Clear_Window
End; { informations }

Procedure Initialisations;
Begin { initialisations }
  Nb_Niveau := 0;
  Num_Ligne := 1;
  If ((Paramcount > 0) And (Not Param))
  Then
    If (Paramcount = 1)
    Then
      Begin
        Nom_Fich_Orig := Paramstr (1);
        Nom_Fich_Dest := Paramstr (1)
      End
    Else
      Begin
        Nom_Fich_Orig := Paramstr (1);
        Nom_Fich_Dest := Paramstr (2)
      End
    {endif}
  Else
    Begin
      Nom_Fich_Orig := 'NONAME';
      Nom_Fich_Dest := 'NONAME';
    End
  {endif};
  Param := True;
  Met_Extension (Nom_Fich_Orig, '.PAS', Nom_Fich_Orig);
  Met_Extension (Nom_Fich_Dest, '.PAS', Nom_Fich_Dest)
End; { initialisations }

Procedure Ask_Nom_Fichier (Chaine : String;
                           Tst_Exist : Boolean;
                           Var Nom1 : String);
Var Nom2   : String;
    Sortie : Boolean;
Begin { ask_nom_fichier }
  Nom1 := Set_Maj_Chaine (Nom1);
  Type_Cadre := 2;
  Window_Fond_Cadre_Bis (2, 2, 79, 3, Red, White, Lightgray);
  Window_Titre (Concat ('Entrez le nom du fichier ', Chaine), Red, Lightgray);
  Textcolor (White);
  Textbackground (Red);
  Repeat
    Clrscr;
    Writeln ('Ancien nom:  ', Nom1);
    Write ('Nouveau nom: ');
    Readln (Nom2);
    Met_Extension (Nom2, '.PAS', Nom2);
    Nom2 := Set_Maj_Chaine (Nom2);
    If ((Tst_Exist) And (Nom2 <> '.PAS'))
    Then
      Sortie := Exist (Nom2)
    Else
      Sortie := True
    {endif}
  Until (Sortie);
  If (Nom2 <> '.PAS')
  Then
    Nom1 := Nom2
  {endif};
  Clear_Window
End; { ask_nom_fichier }

Procedure Nouveau_Fichier_Source (Var Nom_Fich : String; I : Integer);
Begin { nouveau_fichier_source }
  Delete (Nom_Fich, 1, I);
  I := Pos ('}', Nom_Fich);
  If (I > 0)
  Then
    Delete (Nom_Fich, I, Pred (Length (Nom_Fich) - I))
  {endif};
  I := Pos ('*)', Nom_Fich);
  If (I > 0)
  Then
    Delete (Nom_Fich, I, Pred (Length (Nom_Fich) - I))
  {endif};
  I := Pos (' ', Nom_Fich);
  If (I > 0)
  Then
    Delete (Nom_Fich, I, Pred (Length (Nom_Fich) - I))
  {endif}
End; { nouveau_fichier_source }

Procedure Traiter_Fichier (Var Fichier1 : Text; Nom_Fich2 : String);
Var Fichier2 : Text;
    Ch_Maj,
    Chaine   : String;
    I,
    J        : Integer;
Begin { traiter_fichier }
  Writeln ('Linkage de ', Nom_Fich2, ' … partir de la ligne ', Num_Ligne, '.');
  Writeln;
  If Exist (Nom_Fich2)
  Then
    Begin
      Inc (Nb_Niveau);
      Assign (Fichier2, Nom_Fich2);
      Reset (Fichier2);
      While Not (Eof (Fichier2)) Do
        Begin
          Readln (Fichier2, Chaine);
          Gotoxy (5, Pred (Wherey));
          Writeln ('Ligne en cours: ', Num_Ligne, '.     ');
          Ch_Maj := Set_Maj_Chaine (Chaine);
          I := Pos ('{$I ', Ch_Maj);
          J := Pos ('(*$I ', Ch_Maj);
          If ((I > 0) And (Nb_Niveau < 15))
          Then
            Begin
              Nouveau_Fichier_Source (Ch_Maj, Succ (I));
              Traiter_Fichier (Fichier1, Ch_Maj)
            End
          Else
            If ((J > 0) And (Nb_Niveau < 15))
            Then
              Begin
                Nouveau_Fichier_Source (Ch_Maj, Succ (J));
                Traiter_Fichier (Fichier1, Ch_Maj)
              End
            Else
              Begin
                Writeln (Fichier1, Chaine);
                Inc (Num_Ligne)
              End
            {endif}
          {endif}
        End
      {endwhile};
      Writeln ('Fin du linkage de ', Nom_Fich2, ' en ligne ', Num_Ligne, '.');
      Dec (Nb_Niveau);
      Close (Fichier2)
    End
  Else
    Writeln ('Ce fichier n''existe pas, veuillez v‚rifier puis recommencer...')
  {endif}
End; { traiter_fichier }

Procedure Traitement;
Var Nom2 : String;
    Bug  : Boolean;
Begin { traitement }
  If (Exist (Nom_Fich_Orig))
  Then
    Begin
      Type_Cadre := 6;
      Window_Cadre_Bis (1, 2, 79, 4, Yellow, Green);
      Window_Titre ('Linkeur de fichiers Turbo Pascal.', Black+Blink, Green);
      Window_Fond_Cadre_Bis (1, 2, 80, 20, Lightgray, Red, Blue);
      Window_Titre (Concat ('Linkage de: ', Nom_Fich_Orig, ' dans ', Nom_Fich_Dest), White, Blue);
      Textcolor (Black);
      Textbackground (Lightgray);
      Clrscr;
      Met_Extension (Nom_Fich_Dest, '.$$$', Nom_Fich_Dest);
      Assign (Fichier1, Nom_Fich_Dest);
      Rewrite (Fichier1);
      Traiter_Fichier (Fichier1, Nom_Fich_Orig);
      Close (Fichier1);
      Met_Extension (Nom_Fich_Dest, '.PAS', Nom2);
      Cree_Bak (Nom2);
      Bug := Renomme (Nom_Fich_Dest, Nom2);
      Writeln;
      Writeln ('Fin de traitement du fichier: ', Nom2);
      Attente_Appuit_Touche;
      Clear_Window
    End
  {endif}
End; { traitement }

Function Recommencer : Boolean;
Var Carac : Char;
Begin { recommencer }
  Type_Cadre := 9;
  Window_Fond_Cadre_Bis (2, 2, 79, 2, Black, White, Lightgray);
  Window_Titre ('Voulez-vous modifier un autre fichier ?', Red, Lightgray);
  Textcolor (White);
  Textbackground (Black);
  Repeat
    Clrscr;
    Affic_Center ('Votre r‚ponse (O/N): ');
    Carac := Upcase (Readkey);
    Write (Carac)
  Until ((Carac = 'O') Or (Carac = 'N'));
  Recommencer := (Carac = 'O')
End; { recommencer }

Begin { lk_pascal }
      init_olf_message (mess_freeware);
      init_licence ('LKPA');
      init_olf_software ('Linker Pascal '+ver_num, #155' Patrick Pr‚martin '+ver_dat);
  Reset_Screen;
  Informations;
  Repeat
    Initialisations;
    Ask_Nom_Fichier ('source', True, Nom_Fich_Orig);
    Ask_Nom_Fichier ('destination', False, Nom_Fich_Dest);
    Traitement
  Until (Not Recommencer);
  Reset_Screen
End. { lk_pascal }
