MODULE PunycodeTests;  (* loksh PunycodeTests.Run: the test programs of voc's punycode port *)

(* TestPunycode (tests/) and TestIDNA (voc's src/test/confidence/library) check in their bodies
  and write a line when all their checks passed; a failed assertion stops them with a trap.
  Importing them runs the bodies when PunycodeTests is loaded. *)

IMPORT TestPunycode, TestIDNA, out;

PROCEDURE Run*;
BEGIN
  out.String("PunycodeTests: 2 test modules passed"); out.Ln
END Run;

END PunycodeTests.
