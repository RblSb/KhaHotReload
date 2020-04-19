package;

import utest.Runner;
import utest.ui.Report;

class Main {

	static function main() {
		final runner = new Runner();
		runner.addCases(test.parser);
		Report.create(runner);
		runner.run();
	}

}
