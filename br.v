import os
import flag

const (
	data_root = $env('DATA_ROOT')
	alefbet = '׀־׃ אבגדהוזחטיכלמנסעפצקרשתםןףץך'
)

fn main() {
	mut fprs := flag.new_flag_parser(os.args)
	fprs.application('br')
	fprs.version('0.0.1')
	fprs.description('Bible Reader')
	fprs.skip_executable()

	listbooks := fprs.bool('list', `l`, false, 'List books')
	mut version := fprs.string('version', `v`, 'kjv', 'Bible version')

	additional_args := fprs.finalize() or {
		eprintln(err)
		println(fprs.usage())
		return
	}

	ot := "
		gen, exo, lev, num, deu, jos, jdg, rut,
		1sa, 2sa, 1ki, 2ki, 1ch, 2ch, ezr, neh,
		est, job, psa, pro, ecc, sng, isa, jer,
		lam, ezk, dan, hos, jol, amo, oba, jon,
		mic, nam, hab, zep, hag, zec, mal
	"
	nt := "
		mat, mrk, luk, jhn, act, rom, 1co, 2co,
		gal, eph, php, col, 1th, 2th, 1ti, 2ti,
		tit, phm, heb, jas, 1pe, 2pe, 1jn, 2jn,
		3jn, jud, rev
	"

	books := "$ot, $nt"

	if listbooks {
		println("Old Testament")
		println(ot)
		println("New Testament")
		println(nt)
		return
	}

	booklist_ot := ot.split(',').map(it.trim(' \n\t'))
	booklist := books.split(',').map(it.trim(' \n\t'))

	if additional_args.len < 2 {
		println("Usage: br BOOK CHAPTER [VERSES] [OPTIONS]")
		return
	}

	book := additional_args[0]
	chapter := additional_args[1].int()
	if chapter < 1 {
		eprintln("Invalid chapter number")
		return
	}
	mut verses := ''
	if additional_args.len == 3 {
		verses = additional_args[2]
	}

	if (version == 'wlc' && !booklist_ot.contains(book.to_lower()))
		|| !booklist.contains(book.to_lower())
	{
		eprintln("'$book' is not found in ${version.to_upper()}")
		return
	}

	mut path := "$data_root/$version/"
	list := os.execute("ls $path | awk '/${book.to_upper()}/ && /$chapter/'")
	files := list.output.split('\n')
	// println(files)

	path += files[0]
	txt := os.read_file(path)!

	lines := txt.split('\n')[2..]

	mut filtered := []string{}
	if version == 'wlc' {
		filtered = filter(lines.join('\n'))
	}
	else {
		for ln in 0 .. lines.len-1 {
			filtered << "${ln+1} ${lines[ln]}"
		}
	}

	if verses != '' {
		parts := verses.split(':')
		from := parts[0].int() - 1
		mut to := from + 1
		if parts.len > 1 {to = parts[1].int()}

		if to < from {
			to = filtered.len
		}

		if from < 1 || to > filtered.len || from > filtered.len {
			eprintln("This chapter has $filtered.len verses")
			return
		}

		filtered = filtered[from .. to]
	}

	println(filtered.join_lines())
}

fn filter(txt string) []string {
	mut longest := 0
	for line in txt.split('\n') {
		if line == '' {continue}

		mut len := 0
		for ch in line.runes() {
			if alefbet.contains(ch.str()) {len += 1}
		}

		if len > longest {
			longest = len
		}
	}

	mut lines := []string{}
	mut filtered := []rune{}
	mut lc := 1
	for line in txt.split('\n') {
		if line == '' {continue}
		for ch in line.runes() {
			if alefbet.contains(ch.str()) {filtered << ch}
			// filtered << ch
		}
		ln := filtered.reverse().map(it.str()).join('')
		mut pad := ''
		for _ in 0 .. longest-filtered.len {pad += ' '}
		lines << pad + ln + " $lc"
		filtered = []
		lc += 1
	}
	return lines
}