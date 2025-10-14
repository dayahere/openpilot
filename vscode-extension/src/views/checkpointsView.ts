import * as vscode from 'vscode';
import { CheckpointManager } from '../utils/checkpointManager';

export class CheckpointsViewProvider implements vscode.TreeDataProvider<CheckpointItem> {
  private _onDidChangeTreeData = new vscode.EventEmitter<CheckpointItem | undefined | void>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;

  constructor(private checkpointManager: CheckpointManager) {}

  refresh(): void {
    this._onDidChangeTreeData.fire();
  }

  getTreeItem(element: CheckpointItem): vscode.TreeItem {
    return element;
  }

  getChildren(): Promise<CheckpointItem[]> {
    const checkpoints = this.checkpointManager.getCheckpoints();
    return Promise.resolve(
      checkpoints.map(
        (checkpoint) =>
          new CheckpointItem(
            checkpoint.description || 'Unnamed Checkpoint',
            new Date(checkpoint.timestamp).toLocaleString(),
            checkpoint.id
          )
      )
    );
  }
}

class CheckpointItem extends vscode.TreeItem {
  public contextValue: string;

  constructor(
    public readonly label: string,
    tooltipText: string,
    public readonly checkpointId: string
  ) {
    super(label, vscode.TreeItemCollapsibleState.None);
    this.tooltip = tooltipText;
    this.contextValue = 'checkpoint';
  }
}
