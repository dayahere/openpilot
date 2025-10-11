import * as vscode from 'vscode';
import { Checkpoint, CheckpointState, CodeChange } from '@openpilot/core';
import { generateId, getCurrentTimestamp } from '@openpilot/core';

export class CheckpointManager {
  private checkpoints: Checkpoint[] = [];

  constructor(private context: vscode.ExtensionContext) {
    this.loadCheckpoints();
  }

  async createCheckpoint(sessionId: string, description: string): Promise<Checkpoint> {
    const state = await this.captureState();

    const checkpoint: Checkpoint = {
      id: generateId(),
      sessionId,
      timestamp: getCurrentTimestamp(),
      state,
      description,
    };

    this.checkpoints.push(checkpoint);
    this.saveCheckpoints();

    return checkpoint;
  }

  async restoreCheckpoint(checkpointId: string): Promise<void> {
    const checkpoint = this.checkpoints.find((c) => c.id === checkpointId);
    if (!checkpoint) {
      throw new Error('Checkpoint not found');
    }

    await this.applyState(checkpoint.state);
  }

  getCheckpoints(): Checkpoint[] {
    return this.checkpoints;
  }

  deleteCheckpoint(checkpointId: string): void {
    this.checkpoints = this.checkpoints.filter((c) => c.id !== checkpointId);
    this.saveCheckpoints();
  }

  private async captureState(): Promise<CheckpointState> {
    const codeChanges: CodeChange[] = [];

    // Capture all open editors
    for (const editor of vscode.window.visibleTextEditors) {
      const document = editor.document;
      if (document.uri.scheme === 'file') {
        codeChanges.push({
          filePath: document.uri.fsPath,
          before: document.getText(),
          after: document.getText(),
          timestamp: getCurrentTimestamp(),
        });
      }
    }

    return {
      messages: [],
      codeChanges,
    };
  }

  private async applyState(state: CheckpointState): Promise<void> {
    // Apply code changes
    for (const change of state.codeChanges) {
      try {
        const uri = vscode.Uri.file(change.filePath);
        const document = await vscode.workspace.openTextDocument(uri);
        const edit = new vscode.WorkspaceEdit();
        const fullRange = new vscode.Range(
          0,
          0,
          document.lineCount,
          document.lineAt(document.lineCount - 1).text.length
        );
        edit.replace(uri, fullRange, change.before);
        await vscode.workspace.applyEdit(edit);
      } catch (error) {
        console.error(`Failed to restore file ${change.filePath}:`, error);
      }
    }
  }

  private loadCheckpoints(): void {
    const stored = this.context.globalState.get<Checkpoint[]>('checkpoints');
    if (stored) {
      this.checkpoints = stored;
    }
  }

  private saveCheckpoints(): void {
    this.context.globalState.update('checkpoints', this.checkpoints);
  }
}
