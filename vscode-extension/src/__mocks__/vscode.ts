export const window = {
  showInformationMessage: jest.fn(),
  showWarningMessage: jest.fn(),
  activeTextEditor: undefined as any,
  registerWebviewViewProvider: jest.fn(),
};

export const workspace = {
  getConfiguration: jest.fn(() => ({
    get: jest.fn(() => undefined),
  })),
  workspaceFolders: undefined as any,
  onDidChangeConfiguration: jest.fn(() => ({ dispose: jest.fn() })),
};

export const languages = {
  registerInlineCompletionItemProvider: jest.fn(),
};

export const commands = {
  executeCommand: jest.fn(),
  registerCommand: jest.fn(() => ({ dispose: jest.fn() })),
};

export const Uri = { parse: (s: string) => ({ fsPath: s }) } as any;

export type ExtensionContext = any;

export const ViewColumn = { One: 1 } as any;

export const Webview = function() {} as any;

export default {
  window,
  workspace,
  languages,
  commands,
  Uri,
  ViewColumn,
} as any;
