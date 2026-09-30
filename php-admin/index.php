<?php
/**
 * VideoVault — browse videos from phpMyAdmin-connected MySQL database
 * Open: http://localhost/video-app/php-admin/  (after copying/symlinking to htdocs)
 * Or run: php -S localhost:8080 in the php-admin folder
 */

$pdo = require __DIR__ . '/db.php';

$videos = $pdo->query(
    'SELECT id, title, category, type, filename, fileSize, createdAt
     FROM Video
     ORDER BY createdAt DESC'
)->fetchAll();

$stats = $pdo->query(
    'SELECT category, COUNT(*) AS count FROM Video GROUP BY category'
)->fetchAll();
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>VideoVault — PHP Admin</title>
  <style>
    * { box-sizing: border-box; margin: 0; padding: 0; }
    body { font-family: system-ui, sans-serif; background: #0a0a0f; color: #fafafa; padding: 2rem; }
    h1 { margin-bottom: 0.5rem; }
    .sub { color: #71717a; margin-bottom: 2rem; }
    .stats { display: flex; gap: 1rem; flex-wrap: wrap; margin-bottom: 2rem; }
    .stat { background: #14141c; border: 1px solid #ffffff1a; border-radius: 12px; padding: 1rem 1.25rem; min-width: 140px; }
    .stat strong { display: block; font-size: 1.5rem; color: #8b5cf6; }
    table { width: 100%; border-collapse: collapse; background: #14141c; border-radius: 12px; overflow: hidden; }
    th, td { padding: 12px 16px; text-align: left; border-bottom: 1px solid #ffffff0d; }
    th { background: #1e1e2a; color: #a1a1aa; font-size: 0.85rem; text-transform: uppercase; }
    tr:hover td { background: #ffffff05; }
    .badge { display: inline-block; padding: 2px 8px; border-radius: 6px; font-size: 0.75rem; background: #8b5cf620; color: #a78bfa; }
    a { color: #8b5cf6; }
  </style>
</head>
<body>
  <h1>VideoVault PHP Admin</h1>
  <p class="sub">Connected to MySQL — same database as Flutter app &amp; Next.js API</p>

  <div class="stats">
    <div class="stat"><strong><?= count($videos) ?></strong> Total videos</div>
    <?php foreach ($stats as $row): ?>
      <div class="stat">
        <strong><?= (int) $row['count'] ?></strong>
        <?= htmlspecialchars($row['category']) ?>
      </div>
    <?php endforeach; ?>
  </div>

  <table>
    <thead>
      <tr>
        <th>Title</th>
        <th>Category</th>
        <th>Type</th>
        <th>Size</th>
        <th>Uploaded</th>
      </tr>
    </thead>
    <tbody>
      <?php if (empty($videos)): ?>
        <tr><td colspan="5" style="text-align:center;color:#71717a;">No videos yet — upload from the Flutter Admin tab</td></tr>
      <?php else: ?>
        <?php foreach ($videos as $v): ?>
          <tr>
            <td><?= htmlspecialchars($v['title']) ?></td>
            <td><span class="badge"><?= htmlspecialchars($v['category']) ?></span></td>
            <td><?= htmlspecialchars($v['type']) ?></td>
            <td><?= $v['fileSize'] ? number_format($v['fileSize'] / 1048576, 1) . ' MB' : '—' ?></td>
            <td><?= htmlspecialchars($v['createdAt']) ?></td>
          </tr>
        <?php endforeach; ?>
      <?php endif; ?>
    </tbody>
  </table>

  <p style="margin-top:2rem;color:#71717a;font-size:0.9rem;">
    Manage raw data in <a href="http://localhost/phpmyadmin" target="_blank">phpMyAdmin</a>
    → database <strong>videovault</strong> → table <strong>Video</strong>
  </p>
</body>
</html>
