# about 

a simple project show case how easy it is to use a mixture Bash, NodeJS and [zx](http://https://google.github.io/zx/) in make targets.

Especially when wrangling JSON data, it is a breeze to use JavaScript - even in shell scripts.

We can do all the stuff using just Bash, `jq` and friends, I know ... but ask your colleagues how much they like to read and maintain your Bash scripts.

From my opinion, it is much easier to read and maintain shell code that uses JavaScript for JSON wrangling.

Example: 
```sh
# list all dev dependency packages in uppercase
cat << EOF | node
  console.log(
    Object.keys(
      $(cat package.json).devDependencies ?? []
    )
    .join('\n')
    .toUpperCase()
  )
EOF
```

# prerequisites

- [pnpm](https://pnpm.io/)

- [make](https://www.gnu.org/software/make/)

# setup

- `pnpm install`

# run

- `make`

# dev notes

The example Makefile utilizes [pnpm](https://pnpm.io/) to manage and download on demand the required NodeJS version.