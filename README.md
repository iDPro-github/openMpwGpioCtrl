# Caravel User Project

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0) [![UPRJ_CI](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/user_project_ci.yml) [![Caravel Build](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml/badge.svg)](https://github.com/efabless/caravel_project_example/actions/workflows/caravel_build.yml)

| :exclamation: Important Note            |
|-----------------------------------------|

Overview
========

This repo contains a sample user project that utilizes the
`caravel <https://github.com/efabless/caravel.git>`__ chip user space.
The user project contains a simple GPIO-Control module to read and write
the first 32 bit from the caraval GPIO module in the user space. Furthermore
it implements a FSM to automatically read and write 1024 bits of bit
stream from and to any of the first 32 GPIO ports.

Adress mapping
==============

...