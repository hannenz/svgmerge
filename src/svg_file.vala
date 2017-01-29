using Xml;
using Xml.XPath;

namespace SVGMerge {
	
	public class SVGFile {

		private File path;
		private Xml.Doc *doc;
		private Xml.Node *rootNode;
		private Xml.Node *symbolNode;
		private Xml.Node *defsNode;

		public SVGFile(File path) {

			this.path = path;

			Xml.Parser.init();

			string filepath = path.get_path();
			Xml.Doc* doc = Xml.Parser.parse_file(filepath);
			if (doc == null) {
				error("Could not parse file: %s", filepath);
			}
			rootNode = doc->get_root_element();
			if (rootNode == null) {
				warning("Failed to get XML root element");
				return;
			}
			if (rootNode->name != "svg"){
				warning("This seems not to be a SVG file");
			return;
			}

			// Create a new XML Node for the symbol
			symbolNode = new Xml.Node(null, "symbol");
			symbolNode->new_prop("id", get_id_from_filename());

			defsNode = new Xml.Node(null, "defs");


			// Retrieve all used namespaces
			/* Context ctx = new Context(doc); */
//			Xml.XPath.Object *obj = ctx.eval_expression("//*/namespace::*");
		}

		~SVGFile() {
			Xml.Parser.cleanup();
		}

		public Xml.Node* get_symbol() {
			return symbolNode;
		}
		public Xml.Node* get_defs() {
			return defsNode;
		}
		/**
		* Generate an ID from filename
		*
		* @param string	The filename
		* @return string	The ID
		*/
		protected string get_id_from_filename() {

			string filename = this.path.get_path();
			string r = "";
			string name = filename.replace(".svg", "");
			
			try {
				Regex regex = new Regex("\\W+");
				r = regex.replace(name, name.length, 0, "-");
			}
			catch (GLib.Error e) {
				warning(e.message);
			
			}

			return r;
		}



		public void process() {

			/**
			*
			* ...apply namespaces in <svg> tag
			*/

			for (Xml.Node *iter = rootNode->children; iter != null; iter = iter->next) {

				if (iter->ns != null) {
					if (iter->ns->prefix == "sodipodi") {
						print("Removing node (sodipodi)\n");
						iter->unlink();
					}
				}

				if (iter->type == Xml.ElementType.ELEMENT_NODE) {
					if (iter->name == "metadata") {
						iter->unlink();	
					}
					if (iter->name == "defs") {
						for (Xml.Node *defNode = iter->children; defNode != null; defNode = defNode->next) {
							defsNode->add_child(defNode);
						}
					}
				}

			}
		}
	}
}
