import React from "react";
import heic2any from "heic2any";

import {ImageViewer} from "./image_viewer";
import {TextViewer} from "./text_viewer";
import {PDFViewer} from "./pdf_viewer";
import {NotebookViewer} from "./notebook_viewer";
import {BinaryViewer} from "./binary_viewer";
import {URLViewer} from "./url_viewer";

// 1_000_000 = 1MB
const MAX_FILE_SIZES = {
  _default: 100_000,
  image: 50_000_000,
  pdf: 50_000_000,
  "jupyter-notebook": 50_000_000,
  text: 100_000,
  binary: 100_000,
};

// Checks if the file's size exceeds the maximum file size for a file of that type.
// If the maximum size is not defined for a given type, it checks against the `_default` size.
const isFileTooLarge = (file_size, file_type) => {
  if (file_type in MAX_FILE_SIZES) {
    return file_size > MAX_FILE_SIZES[file_type];
  } else {
    return file_size > MAX_FILE_SIZES._default;
  }
};

export class FileViewer extends React.Component {
  // this.props.result_id is used as a flag for the component to
  // know whether it is displaying within the result view.

  constructor(props) {
    super(props);
    this.state = {
      content: "",
      type: "",
      url: "",
      size: 0,
      loading: true,
    };
  }

  componentDidMount() {
    if (!this.props.result_id || this.props.selectedFile !== null) {
      this.set_submission_file(this.props.selectedFile);
    } else {
      this.setState({loading: false});
    }
  }

  // Manually manage a change of selectedFile, as this requires fetching new file data.
  shouldComponentUpdate(nextProps) {
    if (!!this.props.result_id && this.props.selectedFile !== nextProps.selectedFile) {
      this.set_submission_file(nextProps.selectedFile);
      return false;
    } else {
      return true;
    }
  }

  componentDidUpdate(prevProps, prevState) {
    if (
      !this.props.result_id &&
      (prevProps.selectedFile !== this.props.selectedFile ||
        prevProps.submission_id !== this.props.submission_id ||
        prevProps.selectedFileURL !== this.props.selectedFileURL)
    ) {
      this.set_submission_file("");
    }
    // Update file type for use in the submission file panel
    if (
      typeof this.props.handleFileTypeUpdate === "function" &&
      prevState.type !== this.state.type
    ) {
      this.props.handleFileTypeUpdate(this.state.type);
    }
  }

  isNotebook(type) {
    return type === "jupyter-notebook";
  }

  setFileUrl = submission_file_id => {
    let url;
    if (!!this.props.selectedFileURL) {
      url = this.props.selectedFileURL;
    } else {
      url = Routes.download_file_course_assignment_submission_path(
        this.props.course_id,
        this.props.assignment_id,
        this.props.submission_id,
        {
          select_file_id: submission_file_id,
          show_in_browser: true,
          from_codeviewer: true,
        }
      );
    }
    if (["image/heic", "image/heif"].includes(this.props.mime_type)) {
      fetch(url)
        .then(res => res.blob())
        .then(blob => heic2any({blob, toType: "image/jpeg"}))
        .then(conversionResult => {
          this.setState({
            url: URL.createObjectURL(conversionResult),
            loading: false,
          });
        });
    } else {
      this.setState({url: url, loading: false});
    }
  };

  /*
   * Update the contents being displayed with the given submission file id.
   */
  set_submission_file = (submission_file_id, force_text) => {
    if (
      (!this.props.result_id && this.props.selectedFile === null) ||
      submission_file_id === null
    ) {
      this.setState({loading: false, size: 0, type: ""});
      return;
    }
    force_text = !!force_text;

    // TODO: is this the right spot to remove these? Should it be done earlier?
    $(".annotation_text_display").each(function () {
      this.remove();
    });

    this.setState({loading: true, size: 0, url: null}, () => {
      if (!this.props.selectedFileURL) {
        fetch(
          Routes.get_file_course_submission_path(this.props.course_id, this.props.submission_id, {
            submission_file_id: submission_file_id,
            force_text: force_text,
            max_content_size: MAX_FILE_SIZES.text,
          }),
          {credentials: "include"}
        )
          .then(res => res.json())
          .then(body => {
            this.setState({size: body.size, type: body.type});

            if (isFileTooLarge(body.size, body.type)) {
              this.setState({loading: false});
              return;
            }

            if (body.type === "image" || body.type === "pdf" || this.isNotebook(body.type)) {
              this.setState({type: body.type}, () => {
                this.setFileUrl(submission_file_id);
              });
            } else {
              const content = JSON.parse(body.content).replace(/\r?\n/gm, "\n");
              this.setState({
                content: content,
                type: body.type,
                loading: false,
              });
            }
          });
      } else {
        if (
          this.props.selectedFileType === "image" ||
          this.props.selectedFileType === "pdf" ||
          this.isNotebook(this.props.selectedFileType)
        ) {
          this.setState({type: this.props.selectedFileType}, () => {
            this.setFileUrl();
          });
        } else {
          const requestData = {preview: true, force_text: force_text};
          const url = this.props.selectedFileURL;
          const queryString = new URLSearchParams(requestData);
          const requestUrl = `${url}&${queryString}`;
          fetch(requestUrl)
            .then(response => {
              if (response.ok) {
                return response.text();
              }
            })
            .then(res => {
              this.setState({
                content: res.replace(/\r?\n/gm, "\n"),
                type: this.props.selectedFileType,
                loading: false,
              });
            });
        }
      }
    });
  };

  render() {
    let commonProps;
    if (!this.props.selectedFileURL) {
      commonProps = {
        submission_file_id: this.props.selectedFile,
        annotations: this.props.annotations,
        released_to_students: this.props.released_to_students,
        resultView: !!this.props.result_id,
        course_id: this.props.course_id,
        key: `${this.state.type}-viewer`,
      };
    } else {
      commonProps = {
        submission_file_id: null,
        annotations: [],
        released_to_students: null,
        resultView: !!this.props.result_id,
        course_id: this.props.course_id,
        key: `${this.state.type}-viewer`,
      };
    }
    if (this.state.loading) {
      return I18n.t("working");
    } else if (isFileTooLarge(this.state.size, this.state.type)) {
      return I18n.t("submissions.oversize_submission_file");
    } else if (this.state.type === "image") {
      return <ImageViewer url={this.state.url} {...commonProps} />;
    } else if (this.state.type === "pdf") {
      return (
        <PDFViewer
          url={this.state.url}
          annotationFocus={this.props.annotationFocus}
          {...commonProps}
        />
      );
    } else if (this.isNotebook(this.state.type)) {
      return (
        <NotebookViewer
          url={this.state.url}
          annotationFocus={this.props.annotationFocus}
          {...commonProps}
        />
      );
    } else if (this.state.type === "binary") {
      return (
        <BinaryViewer
          content={this.state.content}
          getAnyway={() => this.set_submission_file(this.props.selectedFile, true)}
          {...commonProps}
        />
      );
    } else if (this.state.type === "markusurl") {
      return <URLViewer externalUrl={this.state.content} {...commonProps} />;
    } else if (this.state.type !== "") {
      return (
        <TextViewer
          type={this.state.type}
          content={this.state.content}
          focusLine={this.props.focusLine}
          {...commonProps}
        />
      );
    } else {
      return "";
    }
  }
}
