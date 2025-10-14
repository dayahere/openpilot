// @ts-nocheck
/* eslint-disable @typescript-eslint/no-unused-vars */

// Mock vscode module for Jest tests
const createMockFn = () => {
  const fn: any = (...args: any[]) => undefined;
  fn.mockReturnValue = (val: any) => fn;
  fn.mockResolvedValue = (val: any) => fn;
  fn.mockImplementation = (impl: any) => fn;
  return fn;
};

export const EventEmitter = class {
  event = createMockFn();
  fire = createMockFn();
};

export const window = {
  showInformationMessage: createMockFn(),
  showWarningMessage: createMockFn(),
  activeTextEditor: undefined as any,
  registerWebviewViewProvider: createMockFn(),
};

export const workspace = {
  getConfiguration: createMockFn().mockReturnValue({
    get: createMockFn().mockReturnValue(undefined),
    update: createMockFn(),
  }),
  workspaceFolders: undefined as any,
  onDidChangeConfiguration: createMockFn().mockReturnValue({ dispose: createMockFn() }),
};

export const languages = {
  registerInlineCompletionItemProvider: createMockFn(),
};

export const commands = {
  executeCommand: createMockFn(),
  registerCommand: createMockFn().mockReturnValue({ dispose: createMockFn() }),
};

export const Uri = { 
  parse: (s: string) => ({ fsPath: s, scheme: 'file', path: s }),
  file: (s: string) => ({ fsPath: s, scheme: 'file', path: s }),
} as any;

export const TreeItem = class {
  constructor(public label: string, public collapsibleState?: number) {}
};

export const TreeItemCollapsibleState = {
  None: 0,
  Collapsed: 1,
  Expanded: 2,
};

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
  EventEmitter,
  TreeItem,
  TreeItemCollapsibleState,
} as any;
