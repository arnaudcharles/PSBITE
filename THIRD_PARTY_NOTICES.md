# Third Party Notices

PSBITE includes third party code. The original licences are reproduced below and apply to those
portions only, the rest of PSBITE remains under the project [LICENSE](LICENSE).

## PSSessionCallback (Jordan Borean)

Source: <https://gist.github.com/jborean93/f5605dc05d9395831800753014222b7b>
Proposed in: <https://github.com/arnaudcharles/PSBITE/issues/13>
Itself inspired by: <https://gist.github.com/SeeminglyScience/1b72f0fde3840b275dd23b4104776c5d>

Vendored into:

- `src/functions/private/New-PSSessionCallback.ps1`
- `src/functions/private/Enter-PSSessionWithCallback.ps1`

Both files come from the single upstream file `New-PSSessionWithCallback.ps1`. They were adapted
to the module: split one function per file, `using namespace` statements replaced by fully
qualified type names (the PSModule build concatenates every source file into one `.psm1`, where a
`using` statement would no longer be the first statement), braces and hashtable alignment
restyled for the project's PSScriptAnalyzer settings, and one error-path fix marked inline.

```text
MIT License

Copyright (c) 2026 Jordan Borean (@jborean93) <jborean93@gmail.com>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
