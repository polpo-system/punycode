MODULE IDNATables;  (* the tables of IDNAMapping and IDNAData as data files for polpo *)

(* IDNATables.Extract IDNAMapping.Mod IDNAMapping.txt
   IDNATables.Extract IDNAData.Mod IDNAData.txt

   voc's generated IDNAMapping.Mod and IDNAData.Mod (tools/generate.py) keep their tables in
   string constants d0, d1, ... of up to 768 hexadecimal digits, six for each number. The polpo
   compilers take strings of fewer than 128 characters and 16 KB of them in a module, so polpo's
   versions of the two modules (polpo/src) read the same digits from a file instead. Extract
   writes the strings of the constants d0, d1, ... one after the other, in the order of their
   numbers, into the data file. *)

IMPORT Files, Texts, out;

CONST Max = 4096;  (* constants *)

VAR pos: ARRAY Max OF LONGINT; len: ARRAY Max OF LONGINT;  (* where each string is in the source *)

PROCEDURE Extract*;
VAR A: Texts.Reader; src, dst: ARRAY 256 OF CHAR; f, g: Files.File; R, W: Files.Rider;
  c, p: CHAR; n, k, i, total, at: LONGINT; ok: BOOLEAN;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, src) OR ~Texts.Arg(A, dst) THEN
    out.String("usage: IDNATables.Extract IDNAMapping.Mod IDNAMapping.txt"); out.Ln;
    out.String("  writes the table strings d0, d1, ... of a generated module into a data file"); out.Ln;
    RETURN
  END;
  f := Files.Old(src);
  IF f = NIL THEN out.String(src); out.String(" not found"); out.Ln; RETURN END;
  i := 0; WHILE i < Max DO pos[i] := -1; INC(i) END;
  (* find  d<number> = "  at the start of a line, after two blanks *)
  Files.Set(R, f, 0); p := 0AX; n := -1; at := 0; ok := TRUE;
  Files.Read(R, c);
  WHILE ~R.eof & ok DO
    IF (p = 0AX) & (c = " ") THEN
      Files.Read(R, c); INC(at);
      IF c = " " THEN Files.Read(R, c); INC(at) END;
      IF c = "d" THEN
        Files.Read(R, c); INC(at); k := -1;
        WHILE (c >= "0") & (c <= "9") DO
          IF k < 0 THEN k := 0 END; k := k * 10 + ORD(c) - ORD("0"); Files.Read(R, c); INC(at)
        END;
        IF (k >= 0) & (c = " ") THEN
          Files.Read(R, c); INC(at);
          IF c = "=" THEN Files.Read(R, c); INC(at) END;
          IF c = " " THEN Files.Read(R, c); INC(at) END;
          IF (c = '"') & (k < Max) THEN
            pos[k] := at + 1; i := 0; Files.Read(R, c); INC(at);
            WHILE ~R.eof & (c # '"') DO INC(i); Files.Read(R, c); INC(at) END;
            len[k] := i; IF k > n THEN n := k END
          ELSIF k >= Max THEN ok := FALSE
          END
        END
      END
    END;
    p := c; Files.Read(R, c); INC(at)
  END;
  IF ~ok OR (n < 0) THEN out.String(src); out.String(": no table strings d0, d1, ..."); out.Ln; RETURN END;
  i := 0; WHILE (i <= n) & (pos[i] >= 0) DO INC(i) END;
  IF i <= n THEN out.String(src); out.String(": d"); out.Int(i, 0); out.String(" is missing"); out.Ln; RETURN END;
  g := Files.New(dst); Files.Set(W, g, 0); total := 0; i := 0;
  WHILE i <= n DO
    Files.Set(R, f, pos[i]); k := 0;
    WHILE k < len[i] DO Files.Read(R, c); Files.Write(W, c); INC(k) END;
    INC(total, len[i]); INC(i)
  END;
  Files.Register(g); Files.Close(g);
  out.String(dst); out.String(": "); out.Int(n + 1, 0); out.String(" strings, ");
  out.Int(total, 0); out.String(" digits, "); out.Int(total DIV 6, 0); out.String(" numbers"); out.Ln
END Extract;

END IDNATables.
