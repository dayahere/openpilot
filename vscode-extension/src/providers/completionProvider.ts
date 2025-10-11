import * as vscode from 'vscode';
import { AIEngine, ContextManager, CompletionRequest } from '@openpilot/core';

export class CompletionProvider implements vscode.InlineCompletionItemProvider {
  constructor(
    private aiEngine: AIEngine,
    private contextManager: ContextManager
  ) {}

  async provideInlineCompletionItems(
    document: vscode.TextDocument,
    position: vscode.Position,
    context: vscode.InlineCompletionContext,
    token: vscode.CancellationToken
  ): Promise<vscode.InlineCompletionItem[] | vscode.InlineCompletionList> {
    // Skip if triggered manually or if there's a completion already
    if (context.triggerKind === vscode.InlineCompletionTriggerKind.Explicit) {
      return [];
    }

    try {
      const lineStart = Math.max(0, position.line - 50);
      const lineEnd = position.line + 1;

      const codeContext = await this.contextManager.getCodeContext(
        document.uri.fsPath,
        lineStart,
        lineEnd
      );

      const prompt = 'Complete the code at the cursor position.';

      const request: CompletionRequest = {
        prompt,
        context: codeContext,
        config: this.aiEngine.getConfig(),
      };

      const response = await this.aiEngine.complete(request);

      if (token.isCancellationRequested) {
        return [];
      }

      return response.completions.map(
        (completion) =>
          new vscode.InlineCompletionItem(
            completion.text,
            new vscode.Range(position, position)
          )
      );
    } catch (error) {
      console.error('Completion error:', error);
      return [];
    }
  }
}
