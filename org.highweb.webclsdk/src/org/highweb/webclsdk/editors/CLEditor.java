package org.highweb.webclsdk.editors;

import org.eclipse.ui.editors.text.TextEditor;
import org.eclipse.ui.views.contentoutline.ContentOutlinePage;
import org.eclipse.ui.views.contentoutline.IContentOutlinePage;

public class CLEditor extends TextEditor {

	private ColorManager colorManager;
	private ContentOutlinePage kernelOutlinePage;

	public CLEditor() {
		super();
		colorManager = new ColorManager();
		setSourceViewerConfiguration(new CLConfiguration(colorManager));
		//setSourceViewerConfiguration(new XMLConfiguration(colorManager));
		//setDocumentProvider(new XMLDocumentProvider());
	}
	public void dispose() {
		colorManager.dispose();
		super.dispose();
	}

	public Object getAdapter(Class adapter) {
		if(adapter.equals(IContentOutlinePage.class)) {
			if(kernelOutlinePage == null) {
				kernelOutlinePage = new ContentOutlinePage() {
					
				};
				return kernelOutlinePage;
			}
		}
		return super.getAdapter(adapter);
	}
}
