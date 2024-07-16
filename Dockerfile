FROM rockylinux:8
ADD image /hbb_build
ARG DISABLE_OPTIMIZATIONS=0
RUN bash /hbb_build/build.sh
