import assert from 'assert';
import * as vscode from 'vscode';

describe('OpenPilot VSCode Extension', () => {
  it('should activate and register openpilot.openChat command', async () => {
    // Wait for extension to activate
    const ext = vscode.extensions.getExtension('openpilot.openpilot-vscode');
    await ext?.activate();
    // Check command is registered
    const commands = await vscode.commands.getCommands(true);
  assert.ok(commands.includes('openpilot.openChat'), 'openpilot.openChat command should be registered');
  });
});
