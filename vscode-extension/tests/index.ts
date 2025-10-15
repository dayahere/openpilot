// Minimal official VSCode extension test bootstrap
import * as path from 'path';
import Mocha = require('mocha');

export function run(): Promise<void> {
  const mocha = new Mocha({
    ui: 'bdd',
    color: true
  });
  mocha.addFile(path.resolve(__dirname, './extension.test.js'));
  return new Promise((resolve, reject) => {
    mocha.run((failures: number) => {
      if (failures > 0) {
        reject(new Error(`${failures} tests failed.`));
      } else {
        resolve();
      }
    });
  });
}
