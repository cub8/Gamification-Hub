import globals from "globals"
import pluginJs from "@eslint/js"
import tseslint from "typescript-eslint"
import stylistic from "@stylistic/eslint-plugin"

export default [
  {
    ignores: ["dist/", "api/", "node_modules/", "generated/"],
  },
  pluginJs.configs.recommended,
  ...tseslint.configs.recommended,
  {
    files: ["**/*.{js,mjs,cjs,ts}"],
    plugins: {
      "@stylistic": stylistic,
    },
    languageOptions: {
      globals: {
        ...globals.node,
      },
    },
    rules: {
      "default-param-last": ["warn"],
      "eqeqeq": ["warn", "smart"],
      "no-constructor-return": ["error"],
      "no-empty": ["warn"],
      "no-lonely-if": ["warn"],
      "no-nested-ternary": ["error"],
      "no-shadow": ["error"],
      "no-undef": ["off"],
      "no-undef-init": ["error"],
      "no-unneeded-ternary": ["warn"],
      "no-useless-return": ["warn"],
      "no-var": ["error"],
      "default-case-last": ["warn"],
      "no-else-return": ["warn"],
      "no-duplicate-imports": ["warn"],
      "camelcase": [
        "error",
        {
          "properties": "always",
          "ignoreDestructuring": true,
        },
      ],
      "object-shorthand": ["warn", "always"],
      "operator-assignment": ["warn", "always"],
      "prefer-arrow-callback": ["error"],
      "prefer-exponentiation-operator": ["warn"],
      "prefer-template": ["warn"],
      "yoda": ["warn"],
      "prefer-const": ["off"],
      "@typescript-eslint/no-unused-vars": [
        "error",
        {
          argsIgnorePattern: "^_",
          varsIgnorePattern: "^_",
          caughtErrorsIgnorePattern: "^_",
        },
      ],
      "@typescript-eslint/no-restricted-imports": ["error", {
        "patterns": ["../**", "./**"],
      }],

      "@stylistic/member-delimiter-style": [
        "warn",
        {
          "multiline": {
            "delimiter": "none",
            "requireLast": false,
          },
          "singleline": {
            "delimiter": "semi",
            "requireLast": false,
          },
          "multilineDetection": "brackets",
        },
      ],
      "@stylistic/array-bracket-newline": ["warn", "consistent"],
      "@stylistic/arrow-parens": ["warn"],
      "@stylistic/arrow-spacing": ["warn"],
      "@stylistic/block-spacing": ["warn", "always"],
      "@stylistic/brace-style": ["warn", "1tbs", { "allowSingleLine": true }],
      "@stylistic/comma-dangle": ["warn", "always-multiline"],
      "@stylistic/comma-spacing": ["warn"],
      "@stylistic/comma-style": ["warn"],
      "@stylistic/computed-property-spacing": ["warn"],
      "@stylistic/dot-location": ["warn", "property"],
      "@stylistic/eol-last": ["warn"],
      "@stylistic/function-call-argument-newline": ["warn", "consistent"],
      "@stylistic/function-paren-newline": ["warn", "consistent"],
      "@stylistic/generator-star-spacing": ["warn"],
      "@stylistic/implicit-arrow-linebreak": ["warn"],
      "@stylistic/indent": ["warn", 2],
      "@stylistic/key-spacing": ["warn"],
      "@stylistic/keyword-spacing": ["warn"],
      "@stylistic/linebreak-style": ["warn", "unix"],
      "@stylistic/newline-per-chained-call": ["warn", { "ignoreChainWithDepth": 3 }],
      "@stylistic/no-confusing-arrow": ["warn"],
      "@stylistic/no-extra-semi": ["warn"],
      "@stylistic/no-multiple-empty-lines": ["warn", { "max": 2 }],
      "@stylistic/no-trailing-spaces": ["warn"],
      "@stylistic/no-whitespace-before-property": ["warn"],
      "@stylistic/nonblock-statement-body-position": ["warn"],
      "@stylistic/object-curly-newline": ["warn"],
      "@stylistic/object-curly-spacing": ["warn", "always"],
      "@stylistic/object-property-newline": ["warn", { "allowAllPropertiesOnSameLine": true }],
      "@stylistic/operator-linebreak": ["warn", "after"],
      "@stylistic/padded-blocks": ["warn", "never"],
      "@stylistic/rest-spread-spacing": ["warn"],
      "@stylistic/semi": ["error", "never"],
      "@stylistic/semi-spacing": ["warn"],
      "@stylistic/space-before-blocks": ["warn"],
      "@stylistic/space-before-function-paren": ["warn", "never"],
      "@stylistic/space-in-parens": ["warn", "never"],
      "@stylistic/space-infix-ops": ["error"],
      "@stylistic/spaced-comment": ["warn", "always"],
      "@stylistic/switch-colon-spacing": ["warn"],
      "@stylistic/template-curly-spacing": ["warn"],
      "@stylistic/type-annotation-spacing": ["warn"],
      "@stylistic/wrap-iife": ["error"],
      "@stylistic/yield-star-spacing": ["warn"],
      "@stylistic/quotes": [
        "error",
        "double",
        {
          "avoidEscape": true,
          "allowTemplateLiterals": "always",
        },
      ],
      "no-restricted-syntax": [
        "error",
        {
          "selector": "TSEnumDeclaration",
          "message": "Don't declare enums",
        },
      ],
    },
  },
]
