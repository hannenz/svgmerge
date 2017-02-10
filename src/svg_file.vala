using Xml;
using Xml.XPath;

namespace SVGMerge {
	
	public class SVGFile {

		private File path;
		/* private Xml.Doc *doc; */
		private Xml.Node *root_node;
		private Xml.Node *symbol_node;
		private Xml.Node *defs_node;
		private string prefix;

		public SVGFile(File path, string prefix) {

			this.path = path;
			this.prefix = prefix;

			Xml.Parser.init();

			string filepath = path.get_path();
			debug("Parsing file: " + filepath);
			Xml.Doc* doc = Xml.Parser.parse_file(filepath);
			if (doc == null) {
				error("Could not parse file: %s", filepath);
			}
			root_node = doc->get_root_element();
			if (root_node == null) {
				warning("Failed to get XML root element");
				return;
			}
			if (root_node->name != "svg"){
				warning("This seems not to be a SVG file");
				return;
			}

			// Create a new XML Node for the symbol
			symbol_node = new Xml.Node(null, "symbol");
			symbol_node->new_prop("id", get_id_from_filename());

			// Get viewBox attr and apply to symbol
			string view_box = root_node->get_prop("viewBox");
			symbol_node->set_prop("viewBox", view_box);

			defs_node = new Xml.Node(null, "defs");

			// Retrieve all used namespaces
			/* Context ctx = new Context(doc); */
			///* Xml.XPath.Object *obj = ctx.eval_expression("//*/namespace::*"); */

		}

		~SVGFile() {
			Xml.Parser.cleanup();
		}

		public Xml.Node* get_symbol() {
			return symbol_node;
		}
		public Xml.Node* get_defs() {
			return defs_node;
		}


		/**
		* Generate an ID from filename
		*
		* @param string	The filename
		* @return string	The ID
		*/
		protected string get_id_from_filename() {

			string id = "";
			string filename = this.path.get_basename();
			
			try {
				/* Regex regex = new Regex("\\.svg$"); */
				Regex regex = new Regex("\\..*$");

				id = regex.replace(filename, filename.length, 0, "");
				regex = new Regex("\\W+");
				id = regex.replace(id, id.length, 0, "-");
			}
			catch (GLib.Error e) {
				warning(e.message);
			
			}
			id = prefix + id;
			debug ("id: " + id);
			return id;
		}

		public void process(bool extract_defs) {

			for (Xml.Node *iter = root_node->children; iter != null; iter = iter->next) {

				if (iter->ns != null) {
					if (iter->ns->prefix == "sodipodi") {
						print("Removing node (sodipodi)\n");
						/* iter->unlink(); */
						continue;
					}
				}

				if (iter->type == Xml.ElementType.ELEMENT_NODE) {
					if (iter->name == "metadata") {
						continue;
						/* iter->unlink();	 */
					}
					if (extract_defs) {
						if (iter->name == "defs") {
							for (Xml.Node *def = iter->children; def != null; def = def->next) {
								defs_node->add_child(def);
							}
							continue;
						}
					}
				}
				// Add the remaining
				symbol_node->add_child(iter);
			}
		}
	}
}
