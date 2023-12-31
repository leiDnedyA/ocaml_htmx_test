Testing the when action in lockfiles

  $ . ./helpers.sh

  $ mkdir dune.lock
  $ cat >dune.lock/lock.dune <<EOF
  > (lang package 0.1)
  > EOF

Case with a mix of uncoditional and conditional actions in a progn action
  $ cat >dune.lock/test.pkg <<'EOF'
  > (install
  >  (progn
  >   (when (= foo foo)
  >    (run echo a))
  >   (when (<> foo foo)
  >    (run echo b))
  >   (when (<> foo bar)
  >    (run echo c))
  >   (when (< 1 2)
  >    (run echo d))
  >   (when (< 2 1)
  >    (run echo e))))
  > EOF

  $ build_pkg test
  a
  c
  d
