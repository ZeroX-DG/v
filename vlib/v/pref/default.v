// Copyright (c) 2019-2020 Alexander Medvednikov. All rights reserved.
// Use of this source code is governed by an MIT license
// that can be found in the LICENSE file.
module pref

import (
	filepath
	os
)

pub const (
	default_module_path = os.home_dir() + '.vmodules'
)

pub fn (p mut Preferences) fill_with_defaults() {
	if p.vroot == '' {
		// Location of all vlib files
		p.vroot = filepath.dir(vexe_path())
	}
	vlib_path := filepath.join(p.vroot, 'vlib')
	if p.lookup_path.len == 0 {
		p.lookup_path = ['@vlib', '@vmodules']
	}
	for i, path in p.lookup_path {
		p.lookup_path[i] = path.replace('@vlib', vlib_path).replace('@vmodules', default_module_path)
	}
	rpath := os.realpath(p.path)
	if p.out_name == ''{
		filename := filepath.filename(rpath).trim_space()
		mut base := filename.all_before_last('.')
		if base == '' {
			// The file name is just `.v` or `.vsh` or `.*`
			base = filename
		}
		target_dir := if os.is_dir(rpath) { rpath } else { filepath.dir(rpath) }
		p.out_name = filepath.join(target_dir, base)

		if rpath == '$p.vroot/cmd/v' && os.is_dir('vlib/compiler') {
			// Building V? Use v2, since we can't overwrite a running
			// executable on Windows + the precompiled V is more
			// optimized.
			println('Saving the resulting V executable in `./v2`')
			println('Use `v -o v cmd/v` if you want to replace current ' + 'V executable.')
			p.out_name = 'v2'
		}
	}
	rpath_name := filepath.filename(rpath)
	p.building_v = !p.is_repl && (rpath_name == 'v' || rpath_name == 'vfmt.v')
	if p.os == ._auto {
		// No OS specifed? Use current system
		p.os = get_host_os()
	}
	if p.ccompiler == '' {
		p.ccompiler = default_c_compiler()
	}
	p.is_test = p.path.ends_with('_test.v')
	p.is_script = p.path.ends_with('.v') || p.path.ends_with('.vsh')
	if p.third_party_option == '' {
		p.third_party_option = p.cflags
		$if !windows {
			if !p.third_party_option.contains('-fPIC') {
				p.third_party_option += ' -fPIC'
			}
		}
	}
}

fn default_c_compiler() string {
	// fast_clang := '/usr/local/Cellar/llvm/8.0.0/bin/clang'
	// if os.exists(fast_clang) {
	// return fast_clang
	// }
	// TODO fix $if after 'string'
	$if windows {
		return 'gcc'
	}
	return 'cc'
}

pub fn vexe_path() string {
	vexe := os.getenv('VEXE')
	if vexe != '' {
		return vexe
	}
	real_vexe_path := os.realpath(os.executable())
	os.setenv('VEXE', real_vexe_path, true)
	return real_vexe_path
}
