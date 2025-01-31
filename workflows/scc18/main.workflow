workflow "scc18" {
  on = "push"
  resolves = "execute"
}

action "remove previous builds" {
  uses = "actions/bin/sh@master"
  args = [
    "rm -rf submodules/seissol/build/ submodules/seissol/.scon*"
  ]
}

action "checkout master branch" {
  needs = "remove previous builds"
  uses = "popperized/git@master"
  args = ["-C submodules/seissol checkout master"]
}

action "install dependencies" {
  needs = "checkout master branch"
  uses = "popperized/spack@python3"
  args = [
    "spack", "install",
    "netcdf@4.4.1+mpi ^openmpi@4.0.1 ^hdf5@1.10.5+mpi+fortran+hl",
    "libxsmm@1.12.1+generator",
    "pkg-config@0.29.2",
    "cmake@3.14.5"
  ]
}

action "install scons" {
  needs = "install dependencies"
  uses = "popperized/spack@python3"
  args = "workflows/scc18/scripts/install-scons.sh"
}

action "build" {
  needs = "install scons"
  uses = "popperized/spack@python3"
  args = "workflows/scc18/scripts/build.sh"
  env = {
    SEISSOL_SRC_DIR = "submodules/seissol"
    SCONS_NUM_BUILD_JOBS = "8"
  }
}

action "download input data"{
  needs = "build"
  uses = "popperized/zenodo/download@master"
  env = {
    ZENODO_RECORD_ID = "439946"
    ZENODO_OUTPUT_PATH = "./workflows/scc18/execution"
  }
}

# MPI_NUM_PROCESSES needs to be a multiple of 20
action "execute"{
  needs = "download input data"
  uses = "popperized/spack@python3"
  args = "workflows/scc18/scripts/execute.sh"
  env = {
    SEISSOL_SRC_DIR = "submodules/seissol"
    OMP_NUM_THREADS = 1
    MPI_NUM_PROCESSES = 20
    SEISSOL_END_TIME = 0.000001
  }
}
