using Xml;

namespace SVGMerge {
	
	public class SVGMerge {

		// Options
		protected static string? outfile_path = null;
		protected static string prefix = "";
		protected static bool show_version = false;
		protected static bool extract_defs = false;
		protected static string svg_attributes = "style=\"display:none\"";
		protected static string xmlns = "http://www.w3.org/2000/svg";
		/* protected static  string svgtag = """<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" width="0" height="0" style="width:0;height:0;display:block">"""; */

		protected List<File> files;
		/* private List<string> used_ids = new List<string>(); */

		private const GLib.OptionEntry[] options = {
			{ "version", 'v', 0, OptionArg.NONE, ref show_version, "Display version number", null },
			{ "output",  'o', 0, OptionArg.FILENAME, ref outfile_path, "Specify a file to write the resulting SVG to. Outputs to stdout if omitted", null },
			{ "prefix", 'p', 0, OptionArg.STRING, ref prefix, "Prefix each symbol's id with this string", null },
			{ "extract-defs", 'd', 0, OptionArg.NONE, ref extract_defs, "Extract defs to a global defs block" },
			{ "svg-attr", 'a', 0, OptionArg.STRING, ref svg_attributes, "Attributes to add to the SVG tag" },
			{ "xmlns", 'x', 0, OptionArg.STRING, ref xmlns, "XML namespace to use for the SVG tag"},
			/* { "svgtag", 's', 0, OptionArg.STRING, ref svgtag, "The opening SVG tag to be used" }, */
			{ null }
		};

		public SVGMerge(ref unowned string[] args) {
			// Parse commandline options
			if (!parse_options(ref args)) {
				stderr.printf("Errors. Exiting\n");
				return;
			}

			debug("Using prefix: %s".printf(prefix));
			debug("Output to:    %s".printf(outfile_path));

			// Process remaining arguments as input files
			foreach (string filename in args[1:args.length]) {
				File file = File.new_for_path(filename);
				if (file.query_exists()) {
					files.append(file);
				}
				else {
					stderr.printf("File does not exist: %s\n", filename);
				}
			}
		}

		/**
		* Parse commandlinle options
		*/
		private bool parse_options(ref unowned string[] args) {
			try {
				var opt_context = new OptionContext("input-files");
				opt_context.set_help_enabled(true);
				opt_context.add_main_entries(options, null);
				opt_context.parse(ref args);
			}
			catch (OptionError e) {
				stderr.printf("Error: %s\n".printf(e.message));
				return false;
			}
			return true;
		}

		public void run() {
			if (show_version == true) {
				stdout.printf("1.0\n");
				return;
			}

			if (files.length() == 0) {
				stderr.printf("No input files specified\n");
				return;
			}

			Xml.Doc *out = new Xml.Doc();
			Xml.Node *root = new Xml.Node(null, "svg");
			Xml.Ns *namespace = new Xml.Ns(root, "http://www.w3.org/2000/svg", "svg");
			root->set_prop("style", "display:none");
			out->set_root_element(root);

			Xml.Node *defs = new Xml.Node(null, "defs");
			root->add_child(defs);

			foreach (File file in files) {
				var svg_file = new SVGFile(file, prefix);
				svg_file.process(extract_defs);
				var symbol = svg_file.get_symbol();
				root->add_child(symbol);
				
				if (extract_defs) {
					var s_defs = svg_file.get_defs();
					for(Xml.Node *def = s_defs->children; def != null; def = def->next) {
						defs->add_child(def);
					}
				}
			}

			if (outfile_path == null) {
				out->dump_format(stdout, true);
			}
			else {
				out->save_format_file(outfile_path, 1);
			}
		}
	}

	int main (string[] args) {

		var app = new SVGMerge(ref args);
		app.run();
		
		/* print ("Writing output file"); */
		/* doc->save_file_enc("/tmp/test.svg", "UTF-8"); */
		return 0;
	}
}

