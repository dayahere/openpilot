import * as vscode from 'vscode';
import { SessionManager } from '../utils/sessionManager';

export class HistoryViewProvider implements vscode.TreeDataProvider<HistoryItem> {
  private _onDidChangeTreeData = new vscode.EventEmitter<HistoryItem | undefined | void>();
  readonly onDidChangeTreeData = this._onDidChangeTreeData.event;

  constructor(private sessionManager: SessionManager) {}

  refresh(): void {
    this._onDidChangeTreeData.fire();
  }

  getTreeItem(element: HistoryItem): vscode.TreeItem {
    return element;
  }

  getChildren(element?: HistoryItem): Thenable<HistoryItem[]> {
    if (!element) {
      const sessions = this.sessionManager.getSessions();
      return Promise.resolve(
        sessions.map(
          (session) =>
            new HistoryItem(
              `Session ${new Date(session.createdAt).toLocaleString()}`,
              vscode.TreeItemCollapsibleState.Collapsed,
              session.id
            )
        )
      );
    }

    return Promise.resolve([]);
  }
}

class HistoryItem extends vscode.TreeItem {
  constructor(
    public readonly label: string,
    public readonly collapsibleState: vscode.TreeItemCollapsibleState,
    public readonly sessionId?: string
  ) {
    super(label, collapsibleState);
    this.tooltip = label;
  }
}
