# OsteoBioR (temporal-iso)

R Package to estimate isotopic values in the past and their change over time.

Access App: https://isomemoapp.com/app/osteo-bio-r

## Stan Development
* The precompiled stanmodel objects will appear in a named list called 'stanmodels', 
and you can call them with something like rstan::sampling(stanmodels$foo, ...)
* You can put into src/stan_files/chunks any file that is needed by any .stan file in src/stan_files, 
* You can put into inst/include any C++ files that are needed by any .stan file in src/stan_files, 
but be sure to #include your C++ files in inst/include/meta_header.hpp
* While developing your package use devtools::install('.', local=FALSE) 
to reinstall the package AND recompile Stan programs, or set local=FALSE to skip the recompilation.

