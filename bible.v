import os
import flag

const (
	data_root = $env('DATA_ROOT')
	alefbet = '׀־׃ אבגדהוזחטיכלמנסעפצקרשתםןףץך'
)

fn main() {
	mut fprs := flag.new_flag_parser(os.args)
	fprs.application('bible')
	fprs.version('0.0.1')
	fprs.description('CLI Bible')
	fprs.skip_executable()

	listbooks := fprs.bool('list', `l`, false, 'List books')
	listverses := fprs.bool('list-verses', `r`, false, 'List verses')
	listvers := fprs.bool('list-versions', `s`, false, 'List versions')
	mut version := fprs.string('version', `v`, 'kjv', 'Set bible version')
	mut keyword := fprs.string('keyword', `k`, '', 'Search for keyword')

	if listvers {
		output := os.execute("ls $data_root").output
		println(output)
		return
	}

	if keyword != '' {
		if version == 'wlc' {
			keyword = keyword.runes().reverse().map(it.str()).join('')
			if !os.exists('tmp.txt') {
				path := "$data_root/$version/"
				list := os.execute("ls $path")
				mut filtered := ''
				for file in list.output.split('\n') {
					if file == '' {continue}
					txt := os.read_file(path+file)!
					filtered += filter(txt.split('\n')[2..].join_lines(), false, file).join_lines()+'\n'
				}
				os.write_file('tmp.txt', filtered) or {
					eprintln("Failed to write file: tmp.txt")
					return
				}
			}
			output := os.execute("grep -iE '$keyword' tmp.txt").output
			println(output)
			return
		}

		output := os.execute("grep -iEn '$keyword' $data_root/$version/*").output
		if output == '' { return }
		for line in output.split('\n') {
			if line == '' {continue}
			parts := line.split('.txt:')
			ref := parts[0].split('/').last()
			mut txt := parts[1]
			book_name := ref[0..3]
			book_chap := ref.split('_')[1]
			verse_num := txt.split(':')[0].trim(' ').int() - 2
			txt = txt.split(':')[1]
			println("$book_name $book_chap:$verse_num $txt")
		}
		return
	}

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

	if additional_args.len < 1 {
		println(fprs.usage())
		println('\nExamples:')
		println('bible jdg')
		println('bible psa 2 1:4')
		println('bible -k messiah')
		println('bible -r 3:18')
		return
	}

	mut path := "$data_root/$version/"

	if listverses {
		// TODO:
		target := additional_args[0]
		chapter := target.split(':')[0].trim(' ').int()
		verse := target.split(':')[1].trim(' ').int()

		output := os.execute("ls $path").output.split('\n')
		mut c := 0
		mut current_book := ''
		for book_chap in output {
			if book_chap.trim(' ') == '' {return}
			book_name := book_chap[0..3]
			if book_name != current_book {
				current_book = book_name
				c = 0
			}
			c += 1
			if c != chapter {continue}
			txt := os.read_file("$path/$book_chap")!
			lines := txt.split('\n')[2..]
			if lines.len-1 < verse {continue}
			println("$book_name $chapter:$verse")
			println(lines[verse-1])
			println('')
		}
		return
	}

	book := additional_args[0]
	mut chapter := 0

	if additional_args.len > 1 {
		chapter = additional_args[1].int()
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

	if chapter < 1 {
		n := os.execute("ls $path | grep -i $book | wc -l").output.trim(' ').int()
		println(n)
		return
	}

	list := os.execute("ls $path | awk '/${book.to_upper()}/ && /$chapter/'")
	files := list.output.split('\n')
	// println(files)

	path += files[0]
	txt := os.read_file(path)!

	lines := txt.split('\n')[2..]

	mut filtered := []string{}
	if version == 'wlc' {
		filtered = filter(lines.join('\n'), true, '')
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

		if from < 0 || to > filtered.len || from > filtered.len {
			eprintln("Verse number out of range: this chapter has $filtered.len verses")
			return
		}

		filtered = filtered.clone()[from .. to]
	}

	println(filtered.join_lines())
}

fn filter(txt string, addpad bool, prfx string) []string {
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
		if addpad { for _ in 0 .. longest-filtered.len {pad += ' '} }
		lines << prfx + pad + ln + " $lc"
		filtered = []
		lc += 1
	}
	return lines
}