MODULE PunycodeVectors;  (* the 47844 vectors of voc's conformance check, against voc's answers *)

(* PunycodeVectors.Run requests.txt output.txt

   requests.txt has the requests voc's tests/check-vectors.py makes (all Unicode 16.0 IDNA
   fixtures, domain names, RFC 3492 samples, Punycode and NFC comparisons), one a line, as
   tests/DomainVectors.Mod reads them: "I hex" a host name in UTF-8 for IDNA.Names, "E scalars"
   to encode, "D hex" to decode with Punycode, "N scalars" to normalize; scalars have six
   hexadecimal digits each. output.txt has the answers of voc's DomainVectors for them, a line
   each, which check-vectors.py found equal to those of its reference. Run answers each request
   as DomainVectors does and compares the answer with the line of output.txt. *)

IMPORT Files, Texts, out, IDNA, Punycode, UnicodeNFC;

CONST Max = 16384;

VAR
  request, expected, answer: ARRAY Max OF CHAR; n: LONGINT;  (* answer[0..n) *)
  bytes, encoded: ARRAY Max OF CHAR;
  scalars, normalized: ARRAY 4096 OF LONGINT;
  checks, failed: LONGINT;

PROCEDURE Hex(c: CHAR): LONGINT;
BEGIN
  IF c <= "9" THEN RETURN ORD(c) - ORD("0") END;
  IF c >= "a" THEN RETURN ORD(c) - ORD("a") + 10 END;
  RETURN ORD(c) - ORD("A") + 10
END Hex;

PROCEDURE Put(c: CHAR);
BEGIN IF n < Max - 1 THEN answer[n] := c; INC(n) END
END Put;

PROCEDURE PutHex(value, digits: LONGINT);
VAR d: ARRAY 8 OF CHAR; i: LONGINT;
BEGIN
  i := digits - 1;
  WHILE i >= 0 DO
    IF value MOD 16 < 10 THEN d[i] := CHR(ORD("0") + value MOD 16) ELSE d[i] := CHR(ORD("A") + value MOD 16 - 10) END;
    value := value DIV 16; DEC(i)
  END;
  i := 0; WHILE i < digits DO Put(d[i]); INC(i) END
END PutHex;

PROCEDURE PutInt(x: LONGINT);
VAR d: ARRAY 12 OF CHAR; i: LONGINT;
BEGIN
  IF x < 0 THEN Put("-"); x := -x END;
  i := 0; REPEAT d[i] := CHR(x MOD 10 + ORD("0")); x := x DIV 10; INC(i) UNTIL x = 0;
  WHILE i > 0 DO DEC(i); Put(d[i]) END
END PutInt;

PROCEDURE PutText(VAR text: ARRAY OF CHAR);
VAR i: LONGINT;
BEGIN i := 0; WHILE text[i] # 0X DO PutHex(ORD(text[i]), 2); INC(i) END
END PutText;

(* the answer to request, as tests/DomainVectors.Mod writes it *)
PROCEDURE Answer;
VAR mode: CHAR; i, size, k, v, written, result: LONGINT; ok: BOOLEAN; unicode, ascii: IDNA.String;
BEGIN
  n := 0; mode := request[0]; i := 2; size := 0;
  IF (mode = "I") OR (mode = "D") THEN
    WHILE request[i] # 0X DO bytes[size] := CHR(Hex(request[i]) * 16 + Hex(request[i + 1])); INC(size); INC(i, 2) END;
    bytes[size] := 0X
  ELSE
    WHILE request[i] # 0X DO
      v := 0; k := 0; WHILE k < 6 DO v := v * 16 + Hex(request[i]); INC(i); INC(k) END;
      scalars[size] := v; INC(size)
    END
  END;
  IF mode = "I" THEN
    IDNA.Names(bytes, unicode, ascii, result); PutInt(result);
    IF result = 0 THEN Put(09X); PutText(ascii^); Put(09X); PutText(unicode^) END
  ELSIF mode = "E" THEN
    Punycode.Encode(scalars, size, encoded, written, result); PutInt(result);
    IF result = 0 THEN Put(09X); k := 0; WHILE k < written DO PutHex(ORD(encoded[k]), 2); INC(k) END END
  ELSIF mode = "D" THEN
    Punycode.Decode(bytes, size, normalized, written, result); PutInt(result);
    IF result = 0 THEN Put(09X); k := 0; WHILE k < written DO PutHex(normalized[k], 6); INC(k) END END
  ELSE
    UnicodeNFC.Normalize(scalars, size, normalized, written, ok);
    IF ok THEN PutInt(0); Put(09X); k := 0; WHILE k < written DO PutHex(normalized[k], 6); INC(k) END
    ELSE PutInt(-1)
    END
  END;
  answer[n] := 0X
END Answer;

(* the next line of R into s, FALSE at the end *)
PROCEDURE Line(VAR R: Files.Rider; VAR s: ARRAY OF CHAR): BOOLEAN;
VAR c: CHAR; i: LONGINT;
BEGIN
  i := 0; Files.Read(R, c);
  IF R.eof THEN s[0] := 0X; RETURN FALSE END;
  WHILE ~R.eof & (c # 0AX) DO IF i < LEN(s) - 1 THEN s[i] := c; INC(i) END; Files.Read(R, c) END;
  s[i] := 0X; RETURN TRUE
END Line;

PROCEDURE Run*;
VAR A: Texts.Reader; rname, oname: ARRAY 256 OF CHAR; f, g: Files.File; R, S: Files.Rider; more: BOOLEAN;
BEGIN
  Texts.OpenArgs(A);
  IF ~Texts.Arg(A, rname) OR ~Texts.Arg(A, oname) THEN
    out.String("usage: PunycodeVectors.Run requests.txt output.txt"); out.Ln; RETURN
  END;
  f := Files.Old(rname); g := Files.Old(oname);
  IF (f = NIL) OR (g = NIL) THEN out.String("FAIL: no "); out.String(rname); out.String(" or "); out.String(oname); out.Ln; RETURN END;
  Files.Set(R, f, 0); Files.Set(S, g, 0); checks := 0; failed := 0;
  more := Line(R, request);
  WHILE more DO
    INC(checks);
    IF ~Line(S, expected) THEN expected := "(no answer in the file)" END;
    Answer;
    IF answer # expected THEN
      INC(failed);
      IF failed <= 10 THEN
        out.String("FAIL "); out.Int(checks, 0); out.String(": "); out.String(request); out.Ln;
        out.String("  answer   "); out.String(answer); out.Ln;
        out.String("  expected "); out.String(expected); out.Ln
      END
    END;
    more := Line(R, request)
  END;
  out.String("PunycodeVectors: "); out.Int(checks, 0); out.String(" checks, "); out.Int(failed, 0); out.String(" failed"); out.Ln
END Run;

END PunycodeVectors.
