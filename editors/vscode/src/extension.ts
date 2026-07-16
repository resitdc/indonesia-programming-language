import * as vscode from 'vscode';
import * as path from 'path';
import * as child_process from 'child_process';
import { LanguageClient, LanguageClientOptions, ServerOptions, TransportKind } from 'vscode-languageclient/node';

let client: LanguageClient;

export function activate(context: vscode.ExtensionContext) {
    // Cari binary `rpl`
    const rplPath = findRplBinary();
    if (!rplPath) {
        vscode.window.showWarningMessage(
            'RPL Language Server tidak ditemukan. ' +
            'Install RPL terlebih dahulu: https://github.com/resitdc/indonesia-programming-language'
        );
        return;
    }

    const serverOptions: ServerOptions = {
        command: rplPath,
        args: ['lsp'],
        transport: TransportKind.stdio,
    };

    const clientOptions: LanguageClientOptions = {
        documentSelector: [
            { scheme: 'file', language: 'rpl' },
            { scheme: 'file', language: 'rpl-html' },
        ],
        synchronize: {
            fileEvents: vscode.workspace.createFileSystemWatcher('**/*.rpl'),
        },
    };

    client = new LanguageClient(
        'rpl-lsp',
        'RPL Language Server',
        serverOptions,
        clientOptions
    );

    client.start();

    // Tampilkan status di status bar
    const statusBar = vscode.window.createStatusBarItem(vscode.StatusBarAlignment.Left, 0);
    statusBar.text = '$(check) RPL';
    statusBar.tooltip = 'RPL Language Server aktif';
    statusBar.show();

    context.subscriptions.push(statusBar);
}

export function deactivate(): Thenable<void> | undefined {
    if (client) {
        return client.stop();
    }
    return undefined;
}

function findRplBinary(): string | null {
    // 1. Cek PATH
    const pathEnv = process.env['PATH'] || '';
    const paths = pathEnv.split(path.delimiter);
    for (const p of paths) {
        const fullPath = path.join(p, 'rpl');
        try {
            child_process.execFileSync(fullPath, ['--version'], { stdio: 'ignore' });
            return fullPath;
        } catch { /* lanjut */ }
    }

    // 2. Cek lokasi cargo build
    const home = process.env['HOME'] || process.env['USERPROFILE'] || '';
    const cargoTarget = path.join(home, '.cargo', 'bin', 'rpl');
    try {
        child_process.execFileSync(cargoTarget, ['--version'], { stdio: 'ignore' });
        return cargoTarget;
    } catch { /* lanjut */ }

    return null;
}