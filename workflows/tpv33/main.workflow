workflow "tpv33" {
  on = "push"
  resolves = "execute"
}

action "remove previous builds" {
  uses = "actions/bin/sh@master"
  args = [
    "rm -rf submodules/seissol/build/ submodules/seissol/.scon*"
  ]
}

action "checkout gcc8-fix branch" {
  needs = "remove previous builds"
  uses = "popperized/git@master"
  args = ["-C submodules/seissol checkout gcc8-fix"]
}

action "build" {
  needs = "checkout gcc8-fix branch"
  uses = "./workflows/tpv33/actions/seissol"
  args = [
   "compileMode=release",
   "order=2",
   "parallelization=hybrid",
   "hdf5=yes",
   "metis=yes",
   "commThread=no",
   "compiler=gcc",
   "-j8",
  ]
  env = {
    SEISSOL_SRC_DIR = "submodules/seissol"
  }
}

action "download data and parameters"{
  needs = "build"
  uses = "./workflows/tpv33/actions/seissol"
  runs = ["sh", "-c", "workflows/tpv33/scripts/download.sh"]
  env = {
    SEISSOL_SRC_DIR = "submodules/seissol"
  }
}

action "execute"{
  needs = "download data and parameters"
  uses = "./workflows/tpv33/actions/seissol"
  runs = ["sh", "-c","workflows/tpv33/scripts/execute.sh"]
  env = {
    SEISSOL_SRC_DIR = "submodules/seissol"
    OMP_NUM_THREADS = 1
    MPI_NUM_PROCESSES = 1
    SEISSOL_END_TIME = 0.00001
  }
}
