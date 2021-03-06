﻿using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Data;
using System.Drawing;
using System.Text;
using System.Linq;
using System.Threading.Tasks;
using System.Windows.Forms;
using DevExpress.XtraEditors;
using QuanLyBanHang.BUS;
using QuanLyBanHang.DTO;
using QuanLyBanHang.GUI.SaleFormMDI;

namespace QuanLyBanHang.GUI
{
    public partial class SaleFormGUI : DevExpress.XtraEditors.XtraForm
    {
        private ProductsBUS _productsContext = new ProductsBUS();
        private InvoicesBUS _invoicesContext = new InvoicesBUS();
        public SaleFormGUI()
        {
            InitializeComponent();
            LoadProducts();
        }
        private void LoadProducts()
        {
            flpProduct.Controls.Clear();
            var list = _productsContext.GetProductCanBuy().
                Select(o => new ProductUserControlGUI(o.ProductID, o.ProductName, o.QuantityPerUnit, o.UnitPrice, o.UnitsInStock, this));
            flpProduct.Controls.AddRange(list.ToArray());
        }
        private void CheckProducts()
        {
            var list = dgvDetail.Rows.Cast<DataGridViewRow>().ToList();
            foreach (var item in flpProduct.Controls)
            {
                if (item is ProductUserControlGUI objUS)
                {
                    var obj = list.SingleOrDefault(o => o.Cells[0].Value.ToString() == objUS.ProductID);
                    if (obj != null)
                    {
                        objUS.UnitInStock -= int.Parse(obj.Cells[3].Value.ToString());
                    }
                }
            }
        }
        private void btnSearch_Click(object sender, EventArgs e)
        {
            SearchProductsDialogGUI dialog = new SearchProductsDialogGUI();
            dialog.ShowDialog();
            if (dialog.Result)
            {
                flpProduct.Controls.Clear();
                bool? result;

                var resultList = _productsContext.GetSearchListProduct(dialog.SearchName, dialog.MinUnitPrice, dialog.MaxUnitPrice, out result).
                    Select(o => new ProductUserControlGUI(o.ProductID, o.ProductName, o.QuantityPerUnit, o.UnitPrice, o.UnitsInStock, this));
                if (result == true)
                {
                    flpProduct.Controls.AddRange(resultList.ToArray());
                    CheckProducts();
                }
                else if (result == null)
                {
                    MessageBox.Show("Không tìm thấy.");
                }
                else
                {
                    MessageBox.Show("Lỗi kết nối tới máy chủ.");
                }
            }
        }
        private void btnRefreshList_Click(object sender, EventArgs e)
        {
            LoadProducts();
            CheckProducts();
        }
        private void btnSale_Click(object sender, EventArgs e)
        {
            if (dgvDetail.Rows.Count > 0)
            {
                AddInvoiceDialogGUI dialog = new AddInvoiceDialogGUI(txbTotal.Text);
                dialog.ShowDialog();
                if (dialog.Result)
                {
                    string serverMessage;
                    if (_invoicesContext.AddInvoice(new InvoiceDTO
                    {
                        EmployeeID = dialog.EmployeeID,
                        CustomerID = dialog.CustomerID,
                        Freight = dialog.Freight,
                        InvoiceDate = DateTime.Now
                    },
                    dgvDetail.Rows.Cast<DataGridViewRow>().Select(o => new InvoiceDetailDTO
                    {
                        ProductID = int.Parse(o.Cells[0].Value.ToString()),
                        UnitPrice = decimal.Parse(o.Cells[2].Value.ToString()),
                        Quantity = int.Parse(o.Cells[3].Value.ToString()),
                    }).ToList(), out serverMessage))
                    {
                        MessageBox.Show("Đã bán.\nMã Hóa đơn: "+ serverMessage);
                        btnClear_Click(sender, e);
                        LoadProducts();
                    }
                    else
                    {
                        if (MessageBox.Show("Có lỗi trong quá trình chọn mặt hàng.", "Lỗi.", MessageBoxButtons.YesNo) == DialogResult.Yes)
                        {
                            MessageBox.Show(serverMessage, "Lỗi thông báo từ server.");
                        }
                    }
                }
            }
            else
            {
                MessageBox.Show("Vui lòng chọn mặt hàng.");
            }
        }
        private void btnRemove_Click(object sender, EventArgs e)
        {
            if (dgvDetail.SelectedCells.Count > 0)
            {
                dgvDetail.Rows.RemoveAt(dgvDetail.SelectedCells[0].RowIndex);
                LoadProducts();
                CheckProducts();
                txbTotal.Text = dgvDetail.Rows.Cast<DataGridViewRow>().
                    Sum(o => decimal.Parse(o.Cells[2].Value.ToString()) * decimal.Parse(o.Cells[3].Value.ToString())).ToString();
            }
        }
        private void btnClear_Click(object sender, EventArgs e)
        {
            dgvDetail.Rows.Clear();
            LoadProducts();
            txbTotal.Text = "";
        }
    }
}