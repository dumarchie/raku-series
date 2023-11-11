This README should be generated with a command like:

```
raku --doc=Markdown lib/Series.rakumod > README.md
```

but `Pod::TO::HTML` requires `LibCurl` which depends on
`curl:ver<4>:from<native>` and it's unclear how to install
this library (apparently named _libcurl-4.dll_) on Windows
10 (64-bit) in such a way that it is found by `zef install`.
