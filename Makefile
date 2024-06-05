# disable stone age default rules enabled by default (yacc, cc and stuff)
MAKEFLAGS += --no-builtin-rules

# disable stone age default built-in rule-specific variables enabled by default (yacc, cc and stuff)
MAKEFLAGS += --no-builtin-variables

# warn if unused variables in use
MAKEFLAGS += --warn-undefined-variables

# suppress "entering directory ..." messages
MAKEFLAGS += --no-print-directory

# suppress verbose make output
MAKEFLAGS += --silent

# make bash the default shell for make targets
SHELL != which bash

# .ONESHELL tells make to execute a target recipe as a single SHELL call
# (by default make would execute a recipet line by line in separate SHELL calls
.ONESHELL:

# make to use > as the block character
.RECIPEPREFIX := >

# ensure pnpm is available
ifeq (,$(shell command -v pnpm))
  define PNPM_NOT_FOUND
pnpm is not installed or not in PATH.
Install it using "wget -qO- 'https://get.pnpm.io/install.sh' | sh -"

See more here : https://pnpm.io/installation
  endef
  $(error $(PNPM_NOT_FOUND))
else
  PNPM != command -v pnpm
endif

# path to node binary configured in .npmrc
NODE != $(PNPM) node --import process -e 'console.log(process.execPath)'

# subtitute the pnpm command to start zx using the node interpreter managed by pnpm
ZX := $(PNPM) zx --quiet

ex-nodejs-no-substitution: 
# make expressions (i.e. '$(VARIABLE)') will always be substitued before bash substitution
# "cat <<'EOF'" will leave bash expressions like $$('my command ...') and `my command ...` as is without substitution before passing the content to node
# that's why we do NOT NEED to escape "`" here
# hint : remove '| $(NODE)' to see the substituted content in the terminal without running the node script
> cat <<'EOF' | $(NODE)
> const s = `
> 	# executing make target '$@'
>
>		// output a make variables 
>	  zx is '$(ZX)' 
>   shell is '$(SHELL)' 	
>		// output the result of a executed (by make) shell command
>   current directory is '$(shell pwd)' 
> `;
> console.log(s);
> EOF

ex-nodejs: 
# make expressions (i.e. '$(VARIABLE)') will always be substitued before bash substitution
# 'cat <<EOF' will substitute bash expressions like $$('my command ...') and `my command ...` before passing the content to node
# that's why we need to escape "`" to prevent substitution by the shell
# hint : remove '| $(NODE)' to see the substituted content in the terminal without running the node script
> cat <<EOF | $(NODE)
> const s = \`
> 	# executing make target '$@'
>
> 	// output a make variables 
>	  zx is "$(ZX)" 
>   shell is "$(SHELL)" 	
> 	// output the result of a executed (by make) shell command
>   current directory is "$$(pwd)"
> \`;
> console.log(s);
> EOF

# zx is a nodejs wrapper making external program calls snappy (zx is installed via pnpm)
# see https://google.github.io/zx/ for more info on zx
ex-zx-substitution: 
> cat <<'EOF' | $(ZX)
> const pwd = await $$`pwd`;
> echo`
> 	# executing make target '$@'
>
>		// output a make variables 
>	  zx is "$(ZX)" 									
>   shell is "$(SHELL)" 	
>	  // output the result of the shell command executd before
>   current directory is "$${pwd}"	
> `
> EOF

ex-bash: 
> cat <<EOF
> 	# executing make target '$@'
>
>   // output a make variables 
>   zx is $(ZX)
>   shell is "$(SHELL)"
> 	// output the result of a inline executed shell command
>   current directory is "$$(pwd)"
> EOF

ex-nodejs-json-exec:
> cat <<'EOF' | $(NODE) --experimental-default-type=module
>   console.log("# executing make target '$@'\n");
>	  import { readFile } from 'node:fs/promises';
>		import { exec } from 'node:child_process';
>		import { promisify } from 'node:util';
>
> 	const package_name = JSON.parse(await readFile('package.json')).name;
> 	console.log("package name is '%s'", package_name);
>   
>	 	const { stdout, stderr } = await promisify(exec)('git branch --show-current');
>	 	console.log("current branch is '%s'\n", stdout.trim());
> EOF

ex-nodejs-json-exec-with-bash-improved:
> cat <<'EOF' | $(NODE) 
>		const { log } = console;
>   log("# executing make target '$@'\n");
>
>		const package_json = $(shell cat package.json);
> 	log("package name is '%s'", package_json.name);
>   
>	 	log("current branch is '%s'\n", "$(shell git branch --show-current)");
> EOF

ex-bash-json-exec:
> cat <<EOF
>   # executing make target '$@'
>
> 	package name is '`cat package.json | jq -r .name`'
>   
>	 	current branch is '`git branch --show-current`'
> EOF

ex-zx-json-exec:
> cat <<'EOF' | $(ZX)
>   echo`# executing make target '$@'\n`
>
>		const package_json = JSON.parse(await $$`cat package.json`);
> 	echo`package name is '$${package_json.name}'`
>   
>	 	echo('current branch is ', await $$`git branch --show-current`, '\n');
> EOF

ex-zx-json-exec-with-bash-improved:
> cat <<'EOF' | $(ZX)
>   echo`# executing make target '$@'\n`
>
>   echo`package name is '$${$(shell cat package.json).name}'`
>   
>	 	echo('current branch is ', await $$`git branch --show-current`, '\n');
> EOF

all: ex-bash ex-nodejs ex-zx-substitution ex-nodejs-no-substitution ex-nodejs-json-exec ex-nodejs-json-exec-with-bash-improved ex-zx-json-exec ex-zx-json-exec-with-bash-improved

# tell make that these targets are NOT meant to be files/directories
.PHONY: all ex-bash ex-nodejs ex-zx-substitution ex-nodejs-no-substitution ex-nodejs-json-exec ex-nodejs-json-exec-with-bash-improved ex-zx-json-exec ex-zx-json-exec-with-bash-improved

.DEFAULT_GOAL := all