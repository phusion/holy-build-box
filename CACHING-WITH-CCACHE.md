# Caching compilation results with ccache

If you are in the process of writing a compilation script, then re-running the script over and over is very time-consuming. Holy Build Box includes with ccache so that subsequent compiler runs finish quickly.

You can use ccache by setting the `CC`, `CXX` and `CCACHE_DIR` environment variables.

First, create a directory in which ccache should store its cache files:

    mkdir -p cache

Then invoke the compilation script as follows:

    docker run -t -i --rm \
      -e CC='ccache gcc' \
      -e CXX='ccache g++' \
      -e CCACHE_DIR='/io/cache' \
      -v `pwd`:/io \
      phusion/holy-build-box-64:latest \
      bash /io/compile.sh
