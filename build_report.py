from docx import Document
from docx.enum.section import WD_SECTION
from docx.enum.table import WD_ALIGN_VERTICAL, WD_CELL_VERTICAL_ALIGNMENT, WD_ROW_HEIGHT_RULE
from docx.enum.text import WD_ALIGN_PARAGRAPH, WD_BREAK, WD_LINE_SPACING
from docx.oxml import OxmlElement
from docx.oxml.ns import qn
from docx.shared import Cm, Inches, Pt, RGBColor


OUTPUT = r"D:\n4_hk1\ung_dung_da_nen_tang\giua_ki\BAO_CAO_UNG_DUNG_QUAN_LY_SAN_PHAM.docx"


def set_cell_shading(cell, fill):
    tc_pr = cell._tc.get_or_add_tcPr()
    shd = tc_pr.find(qn("w:shd"))
    if shd is None:
        shd = OxmlElement("w:shd")
        tc_pr.append(shd)
    shd.set(qn("w:fill"), fill)


def set_cell_margins(cell, top=120, start=140, bottom=120, end=140):
    tc = cell._tc
    tc_pr = tc.get_or_add_tcPr()
    tc_mar = tc_pr.first_child_found_in("w:tcMar")
    if tc_mar is None:
        tc_mar = OxmlElement("w:tcMar")
        tc_pr.append(tc_mar)
    for tag, value in (("top", top), ("start", start), ("bottom", bottom), ("end", end)):
        node = tc_mar.find(qn(f"w:{tag}"))
        if node is None:
            node = OxmlElement(f"w:{tag}")
            tc_mar.append(node)
        node.set(qn("w:w"), str(value))
        node.set(qn("w:type"), "dxa")


def set_cell_border(cell, color="D9D9D9", size="8", style="single"):
    tc_pr = cell._tc.get_or_add_tcPr()
    borders = tc_pr.first_child_found_in("w:tcBorders")
    if borders is None:
        borders = OxmlElement("w:tcBorders")
        tc_pr.append(borders)
    for edge in ("top", "left", "bottom", "right", "insideH", "insideV"):
        tag = f"w:{edge}"
        element = borders.find(qn(tag))
        if element is None:
            element = OxmlElement(tag)
            borders.append(element)
        element.set(qn("w:val"), style)
        element.set(qn("w:sz"), size)
        element.set(qn("w:color"), color)


def set_repeat_table_header(row):
    tr_pr = row._tr.get_or_add_trPr()
    tbl_header = OxmlElement("w:tblHeader")
    tbl_header.set(qn("w:val"), "true")
    tr_pr.append(tbl_header)


def set_font(run, name="Arial", size=11, bold=False, color="000000", italic=False):
    run.font.name = name
    run._element.get_or_add_rPr().rFonts.set(qn("w:ascii"), name)
    run._element.get_or_add_rPr().rFonts.set(qn("w:hAnsi"), name)
    run._element.get_or_add_rPr().rFonts.set(qn("w:eastAsia"), name)
    run.font.size = Pt(size)
    run.bold = bold
    run.italic = italic
    run.font.color.rgb = RGBColor.from_string(color)


def add_page_number(paragraph):
    paragraph.alignment = WD_ALIGN_PARAGRAPH.RIGHT
    run = paragraph.add_run("Trang ")
    set_font(run, size=9, color="666666")
    fld_char1 = OxmlElement("w:fldChar")
    fld_char1.set(qn("w:fldCharType"), "begin")
    instr_text = OxmlElement("w:instrText")
    instr_text.set(qn("xml:space"), "preserve")
    instr_text.text = "PAGE"
    fld_char2 = OxmlElement("w:fldChar")
    fld_char2.set(qn("w:fldCharType"), "end")
    run._r.append(fld_char1)
    run._r.append(instr_text)
    run._r.append(fld_char2)


doc = Document()
section = doc.sections[0]
section.page_width = Inches(8.5)
section.page_height = Inches(11)
section.top_margin = Inches(0.75)
section.bottom_margin = Inches(0.7)
section.left_margin = Inches(0.85)
section.right_margin = Inches(0.75)

styles = doc.styles
normal = styles["Normal"]
normal.font.name = "Arial"
normal._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
normal._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
normal._element.rPr.rFonts.set(qn("w:eastAsia"), "Arial")
normal.font.size = Pt(11)
normal.font.color.rgb = RGBColor(0, 0, 0)
normal.paragraph_format.line_spacing = 1.25
normal.paragraph_format.space_after = Pt(6)
normal.paragraph_format.alignment = WD_ALIGN_PARAGRAPH.JUSTIFY

title_style = styles["Title"]
title_style.font.name = "Arial"
title_style._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
title_style._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
title_style.font.size = Pt(22)
title_style.font.bold = True
title_style.font.color.rgb = RGBColor(0, 0, 0)
title_style.paragraph_format.space_after = Pt(16)

for style_name, size, before, after in (("Heading 1", 16, 16, 8), ("Heading 2", 13, 12, 6), ("Heading 3", 11.5, 9, 4)):
    style = styles[style_name]
    style.font.name = "Arial"
    style._element.rPr.rFonts.set(qn("w:ascii"), "Arial")
    style._element.rPr.rFonts.set(qn("w:hAnsi"), "Arial")
    style._element.rPr.rFonts.set(qn("w:eastAsia"), "Arial")
    style.font.size = Pt(size)
    style.font.bold = True
    style.font.color.rgb = RGBColor(0, 0, 0)
    style.paragraph_format.space_before = Pt(before)
    style.paragraph_format.space_after = Pt(after)
    style.paragraph_format.keep_with_next = True

footer = section.footer
footer.distance = Inches(0.25)
add_page_number(footer.paragraphs[0])


def add_p(text="", style=None, bold_lead=None, align=None, space_after=None, keep=False):
    p = doc.add_paragraph(style=style)
    if bold_lead and text.startswith(bold_lead):
        r1 = p.add_run(bold_lead)
        set_font(r1, bold=True)
        r2 = p.add_run(text[len(bold_lead):])
        set_font(r2)
    else:
        r = p.add_run(text)
        set_font(r)
    if align is not None:
        p.alignment = align
    if space_after is not None:
        p.paragraph_format.space_after = Pt(space_after)
    if keep:
        p.paragraph_format.keep_with_next = True
    return p


def add_bullet(text, level=0):
    p = doc.add_paragraph(style="List Bullet" if level == 0 else "List Bullet 2")
    p.paragraph_format.left_indent = Inches(0.25 + level * 0.2)
    p.paragraph_format.first_line_indent = Inches(-0.15)
    r = p.add_run(text)
    set_font(r)
    return p


def add_number(text):
    p = doc.add_paragraph(style="List Number")
    p.paragraph_format.left_indent = Inches(0.28)
    p.paragraph_format.first_line_indent = Inches(-0.18)
    r = p.add_run(text)
    set_font(r)
    return p


def add_code(lines):
    table = doc.add_table(rows=1, cols=1)
    table.autofit = False
    table.columns[0].width = Inches(6.7)
    cell = table.cell(0, 0)
    set_cell_shading(cell, "F3F4F6")
    set_cell_border(cell, "D9D9D9", "6")
    set_cell_margins(cell, 140, 170, 140, 170)
    p = cell.paragraphs[0]
    p.paragraph_format.space_after = Pt(0)
    p.paragraph_format.line_spacing = 1.05
    for idx, line in enumerate(lines.split("\n")):
        if idx:
            p.add_run().add_break()
        run = p.add_run(line)
        set_font(run, name="Courier New", size=9.5)
    doc.add_paragraph().paragraph_format.space_after = Pt(0)


def add_table(headers, rows, widths=None):
    table = doc.add_table(rows=1, cols=len(headers))
    table.autofit = False
    table.alignment = WD_ALIGN_PARAGRAPH.CENTER
    header = table.rows[0]
    set_repeat_table_header(header)
    for i, label in enumerate(headers):
        cell = header.cells[i]
        if widths:
            cell.width = Inches(widths[i])
        set_cell_shading(cell, "1F4E78")
        set_cell_border(cell)
        set_cell_margins(cell)
        cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
        p = cell.paragraphs[0]
        p.alignment = WD_ALIGN_PARAGRAPH.CENTER
        r = p.add_run(label)
        set_font(r, size=10, bold=True, color="FFFFFF")
    for ridx, values in enumerate(rows):
        cells = table.add_row().cells
        for i, value in enumerate(values):
            cell = cells[i]
            if widths:
                cell.width = Inches(widths[i])
            if ridx % 2:
                set_cell_shading(cell, "F5F8FC")
            set_cell_border(cell)
            set_cell_margins(cell)
            cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
            p = cell.paragraphs[0]
            p.alignment = WD_ALIGN_PARAGRAPH.CENTER if i == 0 else WD_ALIGN_PARAGRAPH.LEFT
            p.paragraph_format.space_after = Pt(0)
            r = p.add_run(str(value))
            set_font(r, size=10)
    doc.add_paragraph().paragraph_format.space_after = Pt(0)
    return table


figure_no = 0


def add_image_placeholder(caption, instruction, height=1.9):
    global figure_no
    figure_no += 1
    table = doc.add_table(rows=1, cols=1)
    table.autofit = False
    table.columns[0].width = Inches(6.65)
    row = table.rows[0]
    row.height = Inches(height)
    row.height_rule = WD_ROW_HEIGHT_RULE.AT_LEAST
    cell = row.cells[0]
    set_cell_shading(cell, "FAFAFA")
    set_cell_border(cell, "AAB4C0", "10", "dashed")
    set_cell_margins(cell, 240, 240, 240, 240)
    cell.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
    p = cell.paragraphs[0]
    p.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p.paragraph_format.space_after = Pt(6)
    r = p.add_run("CHÈN ẢNH MINH HỌA TẠI ĐÂY")
    set_font(r, size=11, bold=True, color="5B6573")
    p2 = cell.add_paragraph()
    p2.alignment = WD_ALIGN_PARAGRAPH.CENTER
    p2.paragraph_format.space_after = Pt(0)
    r2 = p2.add_run(instruction)
    set_font(r2, size=9.5, italic=True, color="6B7280")
    cap = doc.add_paragraph()
    cap.alignment = WD_ALIGN_PARAGRAPH.CENTER
    cap.paragraph_format.space_after = Pt(8)
    cap.paragraph_format.keep_with_next = False
    rc = cap.add_run(f"Hình {figure_no}. {caption}")
    set_font(rc, size=10, italic=True)


def add_heading(text, level=1):
    p = doc.add_paragraph(style=f"Heading {level}")
    r = p.add_run(text)
    set_font(r, size={1: 16, 2: 13, 3: 11.5}[level], bold=True)
    return p


# Cover page
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
p.paragraph_format.space_after = Pt(4)
r = p.add_run("[TÊN TRƯỜNG]")
set_font(r, size=13, bold=True)
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = p.add_run("[KHOA / BỘ MÔN]")
set_font(r, size=12, bold=True)

doc.add_paragraph().paragraph_format.space_after = Pt(50)
p = doc.add_paragraph(style="Title")
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = p.add_run("BÁO CÁO GIỮA KỲ")
set_font(r, size=24, bold=True)
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
p.paragraph_format.space_after = Pt(8)
r = p.add_run("ỨNG DỤNG QUẢN LÝ SẢN PHẨM")
set_font(r, size=19, bold=True)
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = p.add_run("Flutter Firebase và Cloudinary")
set_font(r, size=14, italic=True)

doc.add_paragraph().paragraph_format.space_after = Pt(55)
meta = [
    ("Môn học", "[Điền tên môn học]"),
    ("Giảng viên", "[Điền họ tên giảng viên]"),
    ("Sinh viên", "[Điền họ tên sinh viên]"),
    ("Mã số sinh viên", "[Điền MSSV]"),
    ("Lớp", "[Điền lớp]"),
]
table = doc.add_table(rows=len(meta), cols=2)
table.autofit = False
table.alignment = WD_ALIGN_PARAGRAPH.CENTER
for idx, (label, value) in enumerate(meta):
    c1, c2 = table.rows[idx].cells
    c1.width = Inches(1.55)
    c2.width = Inches(3.8)
    for c in (c1, c2):
        set_cell_margins(c, 90, 120, 90, 120)
        set_cell_border(c, "FFFFFF", "0", "nil")
        c.vertical_alignment = WD_CELL_VERTICAL_ALIGNMENT.CENTER
    p1 = c1.paragraphs[0]
    p1.alignment = WD_ALIGN_PARAGRAPH.LEFT
    rr = p1.add_run(label + ":")
    set_font(rr, bold=True)
    p2 = c2.paragraphs[0]
    rr = p2.add_run(value)
    set_font(rr)

doc.add_paragraph().paragraph_format.space_after = Pt(50)
p = doc.add_paragraph()
p.alignment = WD_ALIGN_PARAGRAPH.CENTER
r = p.add_run("TP. Hồ Chí Minh, năm 2026")
set_font(r, size=11)

doc.add_page_break()

add_heading("NỘI DUNG BÁO CÁO", 1)
toc_items = [
    "1. Tổng quan đề tài",
    "2. Phân tích yêu cầu",
    "3. Công nghệ và thư viện sử dụng",
    "4. Thiết kế hệ thống",
    "5. Các bước cài đặt và cấu hình",
    "6. Cài đặt các chức năng",
    "7. Kiểm thử và kết quả",
    "8. Hướng dẫn chạy và sử dụng",
    "9. Kết luận và liên kết nộp bài",
]
for item in toc_items:
    p = doc.add_paragraph()
    p.paragraph_format.left_indent = Inches(0.2)
    p.paragraph_format.space_after = Pt(7)
    r = p.add_run(item)
    set_font(r, size=11.5, bold=True)

add_heading("Danh mục hình minh họa cần bổ sung", 2)
add_p("Các khung hình trong tài liệu đã ghi rõ nội dung cần chụp. Khi hoàn thiện, thay từng khung bằng ảnh tương ứng và giữ nguyên chú thích hình ở phía dưới.")
for item in [
    "Cấu trúc thư mục dự án và lệnh tải thư viện",
    "Cấu hình Firebase Authentication và Cloud Firestore",
    "Cấu hình Cloudinary Upload Preset",
    "Màn hình đăng nhập hoặc đăng ký",
    "Danh sách sản phẩm trên web",
    "Biểu mẫu thêm, sửa và chọn ảnh",
    "Dữ liệu products trong Firestore",
    "Thao tác xóa sản phẩm",
    "Giao diện chạy trên thiết bị di động",
    "Kết quả kiểm thử hoặc log chạy chương trình",
]:
    add_bullet(item)

doc.add_page_break()

add_heading("1 TỔNG QUAN ĐỀ TÀI", 1)
add_heading("1.1 Mục tiêu", 2)
add_p("Đề tài xây dựng ứng dụng quản trị sản phẩm đa nền tảng bằng Flutter. Ứng dụng cho phép người quản trị đăng ký, đăng nhập, theo dõi danh sách sản phẩm theo thời gian thực và thực hiện đầy đủ các thao tác thêm, sửa, xóa. Thông tin sản phẩm được lưu trong Cloud Firestore; ảnh được chọn từ thiết bị, tải lên Cloudinary và lưu đường dẫn vào trường image.")
add_p("Sản phẩm đáp ứng yêu cầu chạy trên nền tảng web và có giao diện thích ứng khi chạy trên điện thoại. Mô hình MVP được sử dụng để tách phần giao diện, xử lý nghiệp vụ và truy cập dữ liệu, giúp mã nguồn dễ đọc, dễ kiểm thử và dễ mở rộng.")

add_heading("1.2 Phạm vi chức năng", 2)
for text in [
    "Đăng ký tài khoản quản trị bằng họ tên, email và mật khẩu.",
    "Đăng nhập, đăng xuất và duy trì trạng thái xác thực bằng Firebase Authentication.",
    "Hiển thị danh sách sản phẩm theo thời gian thực từ collection products.",
    "Thêm, chỉnh sửa và xóa sản phẩm.",
    "Chọn ảnh từ thư viện trên web hoặc điện thoại, kiểm tra dung lượng và tải ảnh lên Cloudinary.",
    "Tìm kiếm sản phẩm theo tên; thống kê số sản phẩm, tổng số lượng và tổng giá trị kho.",
    "Hiển thị giao diện responsive phù hợp với điện thoại, máy tính bảng và web.",
]:
    add_bullet(text)

add_heading("1.3 Kết quả đạt được", 2)
add_p("Ứng dụng đã triển khai đúng bốn trường dữ liệu bắt buộc name, price, soluong và image. ID của sản phẩm được Firestore sinh tự động và chỉ được dùng để định danh document, không được lưu thành một trường bổ sung. Luật Firestore kiểm tra người dùng đã đăng nhập, đúng danh sách trường, đúng kiểu dữ liệu và các điều kiện giá lớn hơn 0, số lượng không âm.")

add_image_placeholder("Cấu trúc thư mục của dự án Flutter", "Chụp cửa sổ VS Code hoặc Android Studio, mở rộng các thư mục lib/models, lib/data, lib/presenters và lib/screens.", 2.0)

add_heading("2 PHÂN TÍCH YÊU CẦU", 1)
add_heading("2.1 Đối chiếu yêu cầu đề bài", 2)
add_table(
    ["STT", "Yêu cầu", "Cách thực hiện trong dự án"],
    [
        ("1", "Cơ sở dữ liệu gồm name, price, soluong, image", "Model Product và collection products chỉ ghi đúng bốn trường bắt buộc."),
        ("2", "Thêm và hiển thị sản phẩm", "CloudinaryProductRepository tạo document mới và lắng nghe snapshots theo thời gian thực."),
        ("3", "Đăng nhập, sửa, xóa và chức năng nâng cao", "Firebase Authentication; form chỉnh sửa; hộp thoại xác nhận xóa; tìm kiếm và thống kê kho."),
        ("4", "Nhập và hiển thị hình ảnh trên di động", "image_picker chọn ảnh, Cloudinary lưu ảnh, Image.network hiển thị ảnh từ secure_url."),
        ("5", "Chạy trên web", "Flutter Web chạy bằng flutter run -d chrome."),
        ("6", "Nộp tệp cơ sở dữ liệu", "Tệp database/products.json có đúng cấu trúc dữ liệu yêu cầu."),
    ],
    [0.45, 2.25, 3.95],
)

add_heading("2.2 Cấu trúc dữ liệu sản phẩm", 2)
add_table(
    ["Trường", "Kiểu dữ liệu", "Ràng buộc", "Ý nghĩa"],
    [
        ("name", "String", "Không rỗng", "Tên sản phẩm"),
        ("price", "Number", "Lớn hơn 0", "Giá bán sản phẩm"),
        ("soluong", "Integer", "Lớn hơn hoặc bằng 0", "Số lượng tồn kho"),
        ("image", "String", "Đường dẫn ảnh", "secure_url do Cloudinary trả về"),
    ],
    [1.0, 1.15, 1.85, 2.65],
)
add_p("Dữ liệu mẫu trong tệp database/products.json:")
add_code('{\n  "name": "Bàn phím cơ",\n  "price": 890000,\n  "soluong": 12,\n  "image": "https://example.com/images/ban-phim-co.jpg"\n}')

add_heading("2.3 Quy tắc nghiệp vụ", 2)
for text in [
    "Người dùng phải đăng nhập mới được đọc, tạo, cập nhật hoặc xóa sản phẩm.",
    "Tên sản phẩm không được để trống; giá phải lớn hơn 0; số lượng phải là số nguyên không âm.",
    "Sản phẩm mới bắt buộc có ảnh. Khi sửa, người dùng có thể giữ ảnh cũ hoặc chọn ảnh mới.",
    "Ảnh chọn từ thiết bị phải nhỏ hơn 5 MB; ứng dụng yêu cầu định dạng JPG, PNG hoặc WebP.",
    "Trước khi xóa, ứng dụng hiển thị hộp thoại xác nhận để tránh thao tác nhầm.",
]:
    add_bullet(text)

add_heading("3 CÔNG NGHỆ VÀ THƯ VIỆN SỬ DỤNG", 1)
add_table(
    ["Thành phần", "Phiên bản hoặc vai trò", "Mục đích"],
    [
        ("Flutter", "SDK giao diện đa nền tảng", "Xây dựng một mã nguồn chạy trên web và di động."),
        ("Dart", "SDK ^3.13.1", "Ngôn ngữ lập trình chính."),
        ("firebase_core", "^5.1.0", "Khởi tạo kết nối Firebase."),
        ("firebase_auth", "^7.0.1", "Đăng ký, đăng nhập và đăng xuất."),
        ("cloud_firestore", "^7.1.0", "Lưu trữ và đồng bộ sản phẩm thời gian thực."),
        ("image_picker", "^1.2.4", "Chọn ảnh từ thư viện thiết bị hoặc trình duyệt."),
        ("http", "^1.6.0", "Gửi MultipartRequest để tải ảnh lên Cloudinary."),
        ("Cloudinary", "Dịch vụ lưu trữ ảnh", "Nhận ảnh, trả secure_url và tối ưu việc phân phối ảnh."),
        ("Firebase CLI", "Triển khai rules", "Đưa firestore.rules lên Firebase."),
    ],
    [1.55, 1.8, 3.3],
)

add_heading("3.1 Lệnh tải thư viện", 2)
add_code("flutter pub get")
add_image_placeholder("Kết quả tải các thư viện của dự án", "Chụp cửa sổ Terminal sau khi chạy lệnh flutter pub get thành công.", 1.55)

add_heading("4 THIẾT KẾ HỆ THỐNG", 1)
add_heading("4.1 Kiến trúc MVP", 2)
add_p("Dự án tổ chức theo mô hình Model View Presenter. Model biểu diễn dữ liệu; View chịu trách nhiệm hiển thị và tiếp nhận thao tác; Presenter xử lý luồng nghiệp vụ rồi gọi Repository để làm việc với dịch vụ bên ngoài. Cách tổ chức này hạn chế việc đặt logic Firebase trực tiếp trong widget.")
add_table(
    ["Tầng", "Tệp tiêu biểu", "Trách nhiệm"],
    [
        ("Model", "product.dart, app_user.dart", "Mô tả cấu trúc Product và AppUser; chuyển đổi Product sang hoặc từ Map."),
        ("View", "auth_screen.dart, product_list_screen.dart, product_form_screen.dart", "Hiển thị giao diện, kiểm tra dữ liệu nhập và nhận tương tác người dùng."),
        ("Presenter", "auth_presenter.dart, product_presenter.dart", "Điều phối đăng nhập, đăng ký và các thao tác CRUD."),
        ("Repository", "firebase_auth_repository.dart, cloudinary_product_repository.dart", "Giao tiếp với Firebase Auth, Firestore và Cloudinary."),
    ],
    [1.0, 2.65, 3.0],
)

add_heading("4.2 Luồng xác thực", 2)
add_number("Người dùng nhập email và mật khẩu trên AuthScreen.")
add_number("AuthPresenter gọi FirebaseAuthRepository.")
add_number("Firebase Authentication xác thực thông tin tài khoản.")
add_number("AuthGate theo dõi authStateChanges và chuyển sang ProductListScreen khi có người dùng.")
add_number("Khi đăng xuất, Firebase xóa phiên và giao diện quay lại màn hình xác thực.")

add_heading("4.3 Luồng lưu sản phẩm và ảnh", 2)
add_number("Người dùng chọn ảnh bằng image_picker; ứng dụng đọc ảnh thành Uint8List.")
add_number("Form kiểm tra tên, giá, số lượng, ảnh và giới hạn dung lượng 5 MB.")
add_number("Presenter gọi create hoặc update trong ProductRepository.")
add_number("Repository tải ảnh bằng HTTP MultipartRequest đến Cloudinary với unsigned upload preset.")
add_number("Cloudinary trả về secure_url; repository gán URL này vào trường image.")
add_number("Dữ liệu name, price, soluong và image được ghi vào document của collection products.")
add_number("Stream snapshots phát dữ liệu mới và danh sách sản phẩm tự động cập nhật.")

add_heading("4.4 Luật bảo mật Firestore", 2)
add_p("Tệp firestore.rules chỉ cho phép thao tác khi request.auth khác null. Khi tạo hoặc cập nhật, rules dùng hasOnly để đảm bảo document không xuất hiện trường ngoài yêu cầu và kiểm tra kiểu dữ liệu trước khi chấp nhận ghi.")
add_code("allow read, delete: if request.auth != null;\nallow create, update: if request.auth != null\n  && request.resource.data.keys().hasOnly([\n    'name', 'price', 'soluong', 'image'\n  ])\n  && request.resource.data.price > 0\n  && request.resource.data.soluong >= 0;")

add_heading("5 CÁC BƯỚC CÀI ĐẶT VÀ CẤU HÌNH", 1)
add_heading("5.1 Chuẩn bị môi trường", 2)
for text in [
    "Cài Flutter SDK và kiểm tra môi trường bằng flutter doctor.",
    "Cài trình duyệt Chrome để chạy Flutter Web hoặc chuẩn bị thiết bị Android / máy ảo.",
    "Mở thư mục dự án và chạy flutter pub get.",
    "Bảo đảm dự án Firebase và Cloudinary đã được cấu hình trước khi chạy.",
]:
    add_number(text)
add_code("flutter doctor\nflutter pub get\nflutter devices")

add_heading("5.2 Cấu hình Firebase Authentication", 2)
add_number("Truy cập Firebase Console và chọn project của ứng dụng.")
add_number("Mở Authentication, chọn Sign-in method.")
add_number("Bật phương thức Email/Password.")
add_number("Thêm ứng dụng Web và Android để lấy thông tin cấu hình tương ứng.")
add_image_placeholder("Firebase Authentication đã bật Email Password", "Chụp Firebase Console tại Authentication > Sign-in method, thể hiện Email/Password ở trạng thái Enabled.", 1.9)

add_heading("5.3 Cấu hình Cloud Firestore", 2)
add_number("Trong Firebase Console, tạo Cloud Firestore.")
add_number("Tạo collection products hoặc để ứng dụng tự tạo document đầu tiên.")
add_number("Mỗi document chỉ nhập bốn trường name, price, soluong và image.")
add_number("Triển khai luật bảo mật bằng Firebase CLI.")
add_code("firebase deploy --only firestore:rules")
add_image_placeholder("Collection products trong Cloud Firestore", "Chụp Firestore Data, mở một document để thấy đủ bốn trường name, price, soluong và image; không thêm trường khác.", 2.1)

add_heading("5.4 Cấu hình Cloudinary", 2)
add_number("Tạo tài khoản hoặc project trên Cloudinary.")
add_number("Vào Settings > Upload > Upload presets.")
add_number("Tạo Upload Preset ở chế độ Unsigned.")
add_number("Cấu hình cloud name và upload preset cho ứng dụng bằng dart-define hoặc tệp cấu hình hiện có.")
add_p("Không đưa API Secret của Cloudinary vào mã nguồn phía client. Ứng dụng chỉ sử dụng unsigned upload preset cho thao tác tải ảnh.")
add_image_placeholder("Cấu hình Unsigned Upload Preset trên Cloudinary", "Chụp màn hình Cloudinary Settings > Upload presets, che thông tin nhạy cảm nếu có.", 1.9)

add_heading("5.5 Chạy ứng dụng", 2)
add_p("Chạy trên trình duyệt Chrome:")
add_code("flutter run -d chrome")
add_p("Chạy trên thiết bị Android sau khi kiểm tra tên thiết bị bằng flutter devices:")
add_code("flutter run -d <device-id>")

add_heading("6 CÀI ĐẶT CÁC CHỨC NĂNG", 1)
add_heading("6.1 Đăng ký và đăng nhập", 2)
add_p("FirebaseAuthRepository chuẩn hóa email bằng cách cắt khoảng trắng và chuyển thành chữ thường. Hàm login dùng signInWithEmailAndPassword; hàm register dùng createUserWithEmailAndPassword rồi cập nhật displayName. Các mã lỗi Firebase được chuyển thành thông báo tiếng Việt để người dùng dễ hiểu.")
add_p("AuthPresenter bật trạng thái loading trong lúc gửi yêu cầu, thông báo lỗi nếu xác thực không thành công và gọi onAuthenticated khi có kết quả hợp lệ.")
add_image_placeholder("Màn hình đăng nhập hoặc đăng ký", "Chụp toàn bộ màn hình xác thực của ứng dụng. Có thể chụp thêm trạng thái báo lỗi dữ liệu nếu muốn.", 2.2)

add_heading("6.2 Hiển thị danh sách sản phẩm", 2)
add_p("CloudinaryProductRepository theo dõi _products.snapshots(), chuyển từng document thành Product và sắp xếp theo tên. ProductPresenter đăng ký stream, chuyển dữ liệu cho View và tắt trạng thái tải sau khi nhận được danh sách.")
add_p("Màn hình danh sách hiển thị hình ảnh, tên, giá và số lượng. Phần tổng quan tính số sản phẩm, tổng số lượng và giá trị kho. Ô tìm kiếm giúp lọc nhanh sản phẩm theo tên.")
add_image_placeholder("Danh sách và thống kê sản phẩm trên nền tảng web", "Chụp màn hình web sau khi đăng nhập, thể hiện danh sách có ảnh và các thẻ thống kê.", 2.35)

add_heading("6.3 Thêm sản phẩm và tải ảnh", 2)
add_p("Khi người dùng chọn ảnh, ImagePicker đọc tệp từ thư viện với chất lượng 85 và chiều rộng tối đa 1600 px. Ứng dụng từ chối ảnh lớn hơn 5 MB. Khi lưu, form bắt buộc tên không rỗng, giá lớn hơn 0, số lượng không âm và sản phẩm mới phải có ảnh.")
add_p("Repository tạo trước một document ID để dùng làm public_id của ảnh. Ảnh được gửi đến Cloudinary trong thư mục product_admin; secure_url trả về được lưu cùng dữ liệu sản phẩm vào Firestore.")
add_image_placeholder("Biểu mẫu thêm sản phẩm và chọn hình ảnh", "Chụp form đã nhập tên, giá, số lượng và đã chọn ảnh nhưng chưa nhấn Thêm sản phẩm.", 2.3)
add_image_placeholder("Sản phẩm mới sau khi lưu", "Chụp sản phẩm vừa thêm trong ứng dụng; nếu cần, đặt cạnh ảnh document tương ứng trong Firestore.", 2.0)

add_heading("6.4 Sửa sản phẩm", 2)
add_p("Khi mở chức năng sửa, form nhận Product hiện tại và điền sẵn tên, giá, số lượng. Người dùng có thể giữ ảnh cũ hoặc chọn ảnh mới. Nếu có ảnh mới, repository tải ảnh lên Cloudinary và cập nhật secure_url trước khi ghi bốn trường vào document cũ.")
add_image_placeholder("Chỉnh sửa thông tin sản phẩm", "Chụp màn hình Sửa sản phẩm trước khi lưu hoặc chụp thông báo Đã cập nhật sản phẩm sau khi lưu.", 2.1)

add_heading("6.5 Xóa sản phẩm", 2)
add_p("Người dùng chọn Xóa từ menu của sản phẩm. Giao diện hiển thị hộp thoại xác nhận; chỉ khi đồng ý, ProductPresenter mới gọi repository.delete. Firestore xóa document theo ID và stream tự động cập nhật danh sách.")
add_image_placeholder("Xác nhận và kết quả xóa sản phẩm", "Chụp hộp thoại xác nhận xóa hoặc thông báo Đã xóa sau khi thao tác thành công.", 1.9)

add_heading("6.6 Tìm kiếm thống kê và responsive", 2)
add_p("Ngoài yêu cầu CRUD cơ bản, ứng dụng có ô tìm kiếm theo tên sản phẩm và ba chỉ số tổng quan: số sản phẩm, tổng số lượng và tổng giá trị kho. LayoutBuilder thay đổi cách sắp xếp thẻ thống kê theo bề rộng màn hình, giúp giao diện phù hợp với web, tablet và điện thoại.")
add_image_placeholder("Giao diện ứng dụng trên thiết bị di động", "Chụp ứng dụng chạy trên điện thoại hoặc Android Emulator, thể hiện ảnh và thông tin sản phẩm rõ ràng.", 2.35)

add_heading("7 KIỂM THỬ VÀ KẾT QUẢ", 1)
add_heading("7.1 Các trường hợp kiểm thử", 2)
add_table(
    ["STT", "Trường hợp", "Kết quả mong đợi"],
    [
        ("1", "Đăng nhập đúng tài khoản", "Chuyển đến màn hình danh sách sản phẩm."),
        ("2", "Đăng nhập sai mật khẩu", "Hiển thị thông báo lỗi, không vào trang quản trị."),
        ("3", "Thêm sản phẩm hợp lệ và có ảnh", "Ảnh được tải lên Cloudinary; Firestore có document đúng bốn trường; danh sách tự cập nhật."),
        ("4", "Bỏ trống tên hoặc nhập giá bằng 0", "Form báo lỗi và không lưu dữ liệu."),
        ("5", "Nhập số lượng âm", "Form báo số lượng phải từ 0 trở lên."),
        ("6", "Chọn ảnh lớn hơn 5 MB", "Ứng dụng thông báo ảnh phải nhỏ hơn 5 MB."),
        ("7", "Sửa thông tin và giữ ảnh cũ", "Dữ liệu cập nhật, URL ảnh không đổi."),
        ("8", "Sửa và chọn ảnh mới", "Cloudinary trả URL mới; Firestore cập nhật trường image."),
        ("9", "Hủy hộp thoại xóa", "Sản phẩm vẫn còn trong danh sách."),
        ("10", "Xác nhận xóa", "Document bị xóa và danh sách cập nhật theo stream."),
        ("11", "Tìm kiếm theo một phần tên", "Chỉ các sản phẩm phù hợp được hiển thị."),
        ("12", "Thu nhỏ cửa sổ hoặc chạy Android", "Bố cục đổi theo bề rộng và không tràn nội dung."),
    ],
    [0.45, 2.55, 3.65],
)

add_heading("7.2 Kiểm thử tự động", 2)
add_p("Dự án có các tệp kiểm thử cho ProductPresenter, giao diện và khả năng responsive. Có thể chạy toàn bộ bộ test bằng lệnh sau:")
add_code("flutter test")
add_p("Khi chụp minh họa, cần bảo đảm Terminal hiển thị dòng kết luận thành công. Nếu có test lỗi, sửa lỗi trước khi đưa ảnh vào bản nộp.")
add_image_placeholder("Kết quả chạy kiểm thử", "Chụp Terminal sau khi flutter test hoàn tất; ảnh nên thể hiện số test và trạng thái All tests passed.", 1.7)

add_heading("7.3 Đánh giá kết quả", 2)
add_p("Về mặt thiết kế, ứng dụng đáp ứng yêu cầu dữ liệu, xác thực, CRUD và xử lý ảnh. Firestore cung cấp cập nhật thời gian thực, Cloudinary tách phần lưu ảnh khỏi cơ sở dữ liệu, còn Flutter giúp dùng chung giao diện cho web và di động. Luật bảo mật và kiểm tra form giảm nguy cơ ghi dữ liệu sai cấu trúc.")
add_p("Khi hoàn thiện bản nộp, cần chạy lại ứng dụng trên Chrome và ít nhất một thiết bị Android, thử đầy đủ luồng thêm, sửa, xóa và đối chiếu trực tiếp dữ liệu trên Firestore.")

add_heading("8 HƯỚNG DẪN CHẠY VÀ SỬ DỤNG", 1)
add_heading("8.1 Quy trình chạy nhanh", 2)
for text in [
    "Mở Terminal tại thư mục gốc của dự án.",
    "Chạy flutter pub get để tải thư viện.",
    "Kiểm tra cấu hình Firebase và Cloudinary.",
    "Chạy flutter run -d chrome cho bản web hoặc chọn device Android.",
    "Đăng ký tài khoản mới hoặc đăng nhập bằng tài khoản đã có.",
]:
    add_number(text)

add_heading("8.2 Quy trình thao tác", 2)
for text in [
    "Nhấn nút thêm sản phẩm, chọn ảnh và nhập name, price, soluong.",
    "Nhấn Thêm sản phẩm và chờ thông báo lưu thành công.",
    "Dùng ô tìm kiếm để lọc danh sách theo tên.",
    "Mở menu của sản phẩm để chọn Sửa hoặc Xóa.",
    "Nhấn đăng xuất khi kết thúc phiên quản trị.",
]:
    add_number(text)

add_heading("8.3 Các lỗi thường gặp", 2)
add_table(
    ["Hiện tượng", "Nguyên nhân thường gặp", "Cách xử lý"],
    [
        ("Màn hình yêu cầu cấu hình", "Thiếu Firebase hoặc Cloudinary dart-define", "Kiểm tra firebase_options.dart, cloudinary_config.dart và lệnh chạy."),
        ("Permission denied khi đọc hoặc ghi", "Chưa đăng nhập hoặc chưa deploy rules", "Đăng nhập lại và chạy firebase deploy --only firestore:rules."),
        ("Upload ảnh thất bại", "Sai cloud name hoặc upload preset; preset chưa Unsigned", "Kiểm tra cấu hình Cloudinary và trạng thái preset."),
        ("Ảnh không hiển thị", "URL image rỗng, sai hoặc mạng bị gián đoạn", "Mở secure_url trên trình duyệt và kiểm tra dữ liệu Firestore."),
        ("Không thấy thiết bị Android", "Chưa bật emulator hoặc USB debugging", "Chạy flutter devices và khởi động lại thiết bị / emulator."),
    ],
    [1.55, 2.45, 2.65],
)

add_heading("9 KẾT LUẬN VÀ LIÊN KẾT NỘP BÀI", 1)
add_heading("9.1 Kết luận", 2)
add_p("Đề tài đã xây dựng ứng dụng quản lý sản phẩm bằng Flutter, Firebase và Cloudinary theo mô hình MVP. Ứng dụng hỗ trợ xác thực người dùng, hiển thị dữ liệu thời gian thực, thêm, sửa, xóa sản phẩm, chọn và hiển thị hình ảnh trên web và di động. Cấu trúc dữ liệu được giới hạn đúng bốn trường name, price, soluong và image theo yêu cầu.")
add_p("Các chức năng nâng cao gồm tìm kiếm, thống kê kho, xác nhận xóa, kiểm tra dữ liệu nhập, xử lý lỗi tiếng Việt và giao diện responsive. Mã nguồn được chia lớp rõ ràng, thuận tiện cho kiểm thử và mở rộng trong các phiên bản tiếp theo.")

add_heading("9.2 Tệp cơ sở dữ liệu nộp kèm", 2)
add_p("Tệp dữ liệu mẫu: database/products.json")
add_p("Tệp này chứa danh sách sản phẩm với đúng bốn trường bắt buộc. Khi nộp bài, đính kèm tệp JSON cùng báo cáo và mã nguồn.")

add_heading("9.3 Liên kết nộp bài", 2)
add_p("Link GitHub source code: [DÁN LINK GITHUB TẠI ĐÂY]", bold_lead="Link GitHub source code:")
add_p("Link video demo: [DÁN LINK VIDEO TẠI ĐÂY]", bold_lead="Link video demo:")

add_heading("9.4 Danh sách kiểm tra trước khi nộp", 2)
for text in [
    "Đã điền đầy đủ thông tin trường, khoa, môn học, giảng viên, sinh viên, MSSV và lớp.",
    "Đã thay toàn bộ khung ảnh bằng ảnh chụp thực tế và giữ chú thích hình.",
    "Đã chạy ứng dụng trên web và Android.",
    "Đã kiểm tra thêm, hiển thị, sửa, xóa, đăng nhập và upload ảnh.",
    "Đã kiểm tra Firestore chỉ có các trường name, price, soluong, image.",
    "Đã nộp database/products.json.",
    "Đã điền link GitHub và link video demo, đồng thời kiểm tra quyền truy cập.",
]:
    p = doc.add_paragraph()
    p.paragraph_format.left_indent = Inches(0.2)
    p.paragraph_format.space_after = Pt(6)
    r = p.add_run("☐ " + text)
    set_font(r)


# Final document properties and pagination behavior
doc.core_properties.title = "Báo cáo ứng dụng quản lý sản phẩm Flutter Firebase Cloudinary"
doc.core_properties.subject = "Báo cáo giữa kỳ ứng dụng đa nền tảng"
doc.core_properties.keywords = "Flutter, Firebase, Firestore, Cloudinary, MVP, CRUD"

for p in doc.paragraphs:
    if p.style.name in ("Heading 1", "Heading 2", "Heading 3"):
        p.paragraph_format.keep_with_next = True
    p.paragraph_format.widow_control = True

doc.save(OUTPUT)
print(OUTPUT)
