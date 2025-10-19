import * as vscode from 'vscode';
// Minimal stub for extension activation
export async function activate(context: vscode.ExtensionContext) {
  console.log('Minimal OpenPilot extension is now active!');
  const disposable = vscode.commands.registerCommand('openpilot.openChat', () => {
    vscode.window.showInformationMessage('OpenPilot Chat activated!');
  });
  context.subscriptions.push(disposable);
}

export function deactivate() {
  console.log('Minimal OpenPilot extension deactivated');
}
