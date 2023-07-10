import os {execute}
import flag

const (
	data_root = $env('DATA_ROOT')
)

fn main() {
	mut fprs := flag.new_flag_parser(os.args)
	fprs.application('br')
	fprs.version('0.0.1')
	fprs.description('Bible Reader')
	fprs.skip_executable()

	// reserve := fprs.bool('reserve', `r`, false, 'Reserve a table')
	mut version := fprs.string('version', `v`, 'wlc', 'Bible version')
	// mut book := fprs.string('name', `n`, '', 'Your name')

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
	".trim(' ')

	pages := [
		050, 040, 027, 036, 034, 024, 021, 004,
		031, 024, 022, 025, 029, 036, 010, 013,
		010, 042, 150, 031, 012, 008, 066, 052,
		005, 048, 012, 014, 004, 009, 001, 004,
		007, 003, 003, 003, 002, 014, 003
	]

	booklist := books.split(',').map(it.trim(' \n\t'))

	list := execute("ls $data_root/$version")
	files := list.output.split('\n')

	println(files)

	println(additional_args.join_lines())
	println(fprs.usage())
}