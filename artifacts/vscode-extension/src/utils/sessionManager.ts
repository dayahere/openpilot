import * as vscode from 'vscode';
import { Session, Message } from '@openpilot/core';
import { generateId, getCurrentTimestamp } from '@openpilot/core';

export class SessionManager {
  private currentSession?: Session;
  private sessions: Session[] = [];

  constructor(private context: vscode.ExtensionContext) {
    this.loadSessions();
  }

  getCurrentSession(): Session | undefined {
    if (!this.currentSession) {
      this.currentSession = this.createSession();
    }
    return this.currentSession;
  }

  createSession(): Session {
    const session: Session = {
      id: generateId(),
      messages: [],
      createdAt: getCurrentTimestamp(),
      updatedAt: getCurrentTimestamp(),
    };

    this.sessions.push(session);
    this.currentSession = session;
    this.saveSessions();

    return session;
  }

  addMessage(message: Message): void {
    if (!this.currentSession) {
      this.currentSession = this.createSession();
    }

    this.currentSession.messages.push(message);
    this.currentSession.updatedAt = getCurrentTimestamp();
    this.saveSessions();
  }

  clearCurrentSession(): void {
    if (this.currentSession) {
      this.currentSession.messages = [];
      this.currentSession.updatedAt = getCurrentTimestamp();
      this.saveSessions();
    }
  }

  getSessions(): Session[] {
    return this.sessions;
  }

  getSession(id: string): Session | undefined {
    return this.sessions.find((s) => s.id === id);
  }

  private loadSessions(): void {
    const stored = this.context.globalState.get<Session[]>('sessions');
    if (stored) {
      this.sessions = stored;
      this.currentSession = this.sessions[this.sessions.length - 1];
    }
  }

  private saveSessions(): void {
    this.context.globalState.update('sessions', this.sessions);
  }
}
