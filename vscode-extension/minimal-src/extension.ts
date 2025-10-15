import * as vscode from 'vscode';
// Minimal stub for extension activation
export async function activate(context: vscode.ExtensionContext) {
  console.log('Minimal OpenPilot extension is now active!');
}

export function deactivate() {
  console.log('Minimal OpenPilot extension deactivated');
}
