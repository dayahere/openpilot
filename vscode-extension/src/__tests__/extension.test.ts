import * as vscode from 'vscode';
import * as assert from 'assert';
import { activate, deactivate } from '../extension';


describe('Extension Tests', () => {
  it('Extension activates without error', async () => {
    try {
      // If activate requires a context, pass undefined or a minimal stub
      await activate(undefined as any);
      assert.ok(true, 'Extension activated successfully');
    } catch (err) {
      assert.fail('Extension activation threw error: ' + err);
    }
  });

  it('Extension deactivates without error', () => {
    try {
      deactivate();
      assert.ok(true, 'Extension deactivated successfully');
    } catch (err) {
      assert.fail('Extension deactivation threw error: ' + err);
    }
  });
});

