"use strict";
"require view";
"require fs";
"require ui";

return view.extend({
	runSort: function(mode) {
		return fs.exec('/usr/bin/menusort', [ mode ]).then(function(res) {
			var out = (res && (res.stdout || res.stderr)) || '';
			ui.addNotification(null, E('div', {}, [
				E('p', {}, _('排序已完成（%s），页面即将强制刷新…').format(mode === 'reverse' ? _('反向') : _('正向'))),
				E('pre', { style: 'white-space:pre-wrap;max-height:40vh;overflow:auto' }, out || _('无输出'))
			]), 'info');

			setTimeout(function() {
				try { window.location.reload(); }
				catch (e) { window.location.href = window.location.href.split('#')[0]; }
			}, 1000);
		}).catch(function(err) {
			ui.addNotification(null, E('p', {}, _('执行失败：%s').format(err && err.message ? err.message : err)), 'danger');
		});
	},

	showLog: function() {
		return fs.read('/tmp/menusort.log').then(function(data) {
			ui.showModal(_('排序日志'), [
				E('pre', { style: 'white-space:pre-wrap;max-height:60vh;overflow:auto' }, data || _('（空）')),
				E('div', { class: 'right' }, [ E('button', { class: 'btn', click: ui.hideModal }, _('关闭')) ])
			]);
		}).catch(function() {
			ui.addNotification(null, E('p', {}, _('暂无日志')), 'warning');
		});
	},

	render: function() {
		return E('div', { class: 'cbi-map' }, [
			E('h2', {}, _('菜单排序')),
			E('div', { class: 'cbi-map-descr' }, [
				_('把 LuCI「服务」菜单按规则重排：英文名应用在前（A-Z），中文名应用在后（拼音）。'),
				E('br'),
				_('安装/升级应用后菜单顺序会被重置，可在此一键修复。')
			]),
			E('div', { class: 'cbi-section' }, [
				E('button', {
					class: 'cbi-button cbi-button-apply',
					style: 'margin-right:8px',
					click: ui.createHandlerFn(this, function() { return this.runSort('forward'); })
				}, _('正向排序（英文 A-Z → 中文拼音）')),
				E('button', {
					class: 'cbi-button cbi-button-reset',
					style: 'margin-right:8px',
					click: ui.createHandlerFn(this, function() { return this.runSort('reverse'); })
				}, _('反向排序（中文倒序 → 英文倒序）')),
				E('button', {
					class: 'cbi-button',
					click: ui.createHandlerFn(this, function() { return this.showLog(); })
				}, _('查看日志'))
			]),
			E('div', { class: 'cbi-section' }, [
				E('h3', {}, _('说明')),
				E('ul', {}, [
					E('li', {}, _('只处理顶层 admin/services 节点，子菜单不动')),
					E('li', {}, _('中文按内置拼音表（2 万字）排序，可实现「同首字母再按全拼」')),
					E('li', {}, _('如需把英文 msgid 显示成中文再排序，可编辑 /etc/menusort.aliases（app=显示名）')),
					E('li', {}, _('底层命令：menusort [forward|reverse]，日志 /tmp/menusort.log'))
				])
			])
		]);
	}
});
