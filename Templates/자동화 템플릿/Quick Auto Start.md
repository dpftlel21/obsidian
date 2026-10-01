<%*
// 단축키용 빠른 자동 시작 스크립트
const currentTime = tp.date.now("HH:mm");
const activeFile = app.workspace.getActiveFile();

if (!activeFile) {
    new Notice('❌ 활성화된 파일이 없습니다');
    return;
}

const content = await app.vault.read(activeFile);
const lines = content.split('\n');

let modified = false;
const updatedLines = [];

for (let line of lines) {
    if (line.includes('🏷️ 계획') && line.includes('⏰')) {
        const timeMatch = line.match(/⏰ (\d{2}:\d{2})/);
        if (timeMatch && timeMatch[1] <= currentTime) {
            const newLine = line.replace('🏷️ 계획', '🏷️ 진행중');
            updatedLines.push(newLine);
            modified = true;
            
            const taskName = line.match(/\[(.*?)\]/)?.[1] || '작업';
            new Notice(`⚡ 즉시 시작: ${taskName} (${timeMatch[1]})`);
        } else {
            updatedLines.push(line);
        }
    } else {
        updatedLines.push(line);
    }
}

if (modified) {
    await app.vault.modify(activeFile, updatedLines.join('\n'));
    new Notice('✅ 작업 상태 즉시 업데이트 완료');
} else {
    new Notice('ℹ️ 시작할 작업이 없습니다');
}
%>