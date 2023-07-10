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
	mut version := fprs.string('version', `v`, 'wlc', 'Bible version')

	additional_args := fprs.finalize() or {
		eprintln(err)
		println(fprs.usage())
		return
	}

	books := "
		gen, exo, lev, num, deu, jos, jdg, rut,
		1sa, 2sa, 1ki, 2ki, 1ch, 2ch, ezr, neh,
		est, job, psa, pro, ecc, sng, isa, jer,
		lam, ezk, dan, hos, jol, amo, oba, jon,
		mic, nam, hab, zep, hag, zec, mal
	"

	if listbooks {
		println(books)
		return
	}

	pages := [
		050, 040, 027, 036, 034, 024, 021, 004,
		031, 024, 022, 025, 029, 036, 010, 013,
		010, 042, 150, 031, 012, 008, 066, 052,
		005, 048, 012, 014, 004, 009, 001, 004,
		007, 003, 003, 003, 002, 014, 003
	]

	booklist := books.split(',').map(it.trim(' \n\t'))

	if additional_args.len < 2 {
		println("Usage: br BOOK CHAPTER [VERSES] [OPTIONS]")
		return
	}

	book := additional_args[0]
	chapter := additional_args[1]
	if additional_args.len == 3 {
		verses := additional_args[2]
	}

	if !booklist.contains(book.to_lower()) {
		eprintln("Invalid book name '$book'")
		return
	}

	mut path := "$data_root/$version/"
	list := os.execute("ls $path | awk '/${book.to_upper()}/ && /$chapter/'")
	file := list.output.trim(' \n')

	path += file
	txt := os.read_file(path)!
	cleaned := clean(txt.split('\n')[2..].join('\n')).join_lines()
	println(cleaned)

	// println(additional_args.join_lines())
	// println(fprs.usage())
}


fn clean(txt string) []string {
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
	mut cleaned := []rune{}
	mut lc := 1
	for line in txt.split('\n') {
		if line == '' {continue}
		for ch in line.runes() {
			if alefbet.contains(ch.str()) {cleaned << ch}
			// cleaned << ch
		}
		ln := cleaned.reverse().map(it.str()).join('')
		mut pad := ''
		for _ in 0 .. longest-cleaned.len {pad += ' '}
		lines << pad + ln + " $lc"
		cleaned = []
		lc += 1
	}
	return lines
}