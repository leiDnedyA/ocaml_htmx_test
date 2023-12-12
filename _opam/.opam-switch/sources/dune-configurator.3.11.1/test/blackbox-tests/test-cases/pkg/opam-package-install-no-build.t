In this test we test the translation of an opam package with only an install step.

  $ . ./helpers.sh
  $ mkrepo

Make a package with only an install step 
  $ mkpkg install-no-build <<EOF
  > opam-version: "2.0"
  > install: ["echo" "just installing"]
  > EOF

  $ mkdir -p $mock_packages/install-no-build/install-no-build.0.0.1/

  $ solve_project <<EOF
  > (lang dune 3.8)
  > (package
  >  (name x)
  >  (allow_empty)
  >  (depends install-no-build))
  > EOF
  Solution for dune.lock:
  install-no-build.0.0.1
  
The lockfile should only contain an install step.

  $ cat dune.lock/install-no-build.pkg 
  (version 0.0.1)
  
  (install
   (run echo "just installing"))

Building should only do the install step.

  $ build_pkg install-no-build 
  just installing
