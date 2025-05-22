module.exports = {
  env: {
    es6: true,
    node: true,
  },
  parserOptions: {
    "ecmaVersion": 2020,  // 2018 → 2020으로 변경
  },
  extends: [],
  rules: {
    // 모든 ESLint 규칙 비활성화
    "require-jsdoc": "off",
    "max-len": "off", 
    "no-unused-vars": "off",
    "linebreak-style": "off",
    "indent": "off",
    "no-trailing-spaces": "off"
  },
  overrides: [],
  globals: {},
};